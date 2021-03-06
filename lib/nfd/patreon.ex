defmodule Nfd.Patreon do
  use Timex
  use Tesla

  alias Tesla.Multipart

  alias Nfd.Account
  alias Nfd.Account.User

  api_patreon_url = "https://www.patreon.com/api/oauth2/v2/"

  # Helper Functions
  defp generate_base_url(host) do
    if host == "localhost" do
      "http://localhost:4000"
    else
      "https://neverfapdeluxe.com"
    end
  end

  defp auth_api_client(access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://www.patreon.com/api/oauth2/v2/"},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, [{"Authorization", "Bearer #{access_token}" }]}
    ]

    Tesla.client(middleware)
  end

  def validate_patreon_code(host, user, code) do
    base_url = generate_base_url(host)
    mp =
      Multipart.new
      |> Multipart.add_field("code", code)
      |> Multipart.add_field("grant_type", "authorization_code")
      |> Multipart.add_field("client_id", System.get_env("PATREON_CLIENT_KEY"))
      |> Multipart.add_field("client_secret", System.get_env("PATREON_SECRET_KEY"))
      |> Multipart.add_field("redirect_uri", "#{base_url}/validate_patreon")

    { :ok, response } = post("https://www.patreon.com/api/oauth2/token", mp, headers: [{"content-type", "x-www-form-urlencoded"}])
    body = Jason.decode!(response.body)
    auth_client = auth_api_client(body["access_token"])

    identity_url = "identity?include=memberships&fields%5Buser%5D=about,created,email,first_name,full_name,image_url,last_name,social_connections,thumb_url,url,vanity"

    { :ok, identityResponse } = auth_client |> get(identity_url)
    identity_body = Jason.decode!(identityResponse.body)

    update_user_information(user, identity_body, body)
  end

  defp update_user_information(user, identity_body, body) do
    # retrieve latest patreon information to update on the profile.
    patreon_user_id =
      case identity_body["data"]["relationships"]["memberships"]["data"] do
        nil -> ""
        [] -> ""
        _ -> identity_body["data"]["relationships"]["memberships"]["data"] |> hd() |> Map.get("id")
      end

    patreon_user_email = identity_body["data"]["attributes"]["email"]
    full_name = identity_body["data"]["attributes"]["full_name"]
    first_name = identity_body["data"]["attributes"]["first_name"]
    last_name = identity_body["data"]["attributes"]["last_name"]
    avatar_url = identity_body["data"]["attributes"]["image_url"]
    # expires in

    case Account.update_user(user, %{
      first_name: first_name,
      last_name: last_name,
      avatar_url: avatar_url,
      patreon_linked: true,
      display_name: full_name,
      patreon_user_id: patreon_user_id,
      patreon_user_email: patreon_user_email,
      patreon_access_token: body["access_token"],
      patreon_refresh_token: body["refresh_token"],
      patreon_expires_in: Timex.shift(Timex.now, days: 30)
    }) do
      {:ok, success} -> IO.inspect success
      {:error, error} -> IO.inspect error
    end
  end

  def fetch_patreon(host, user) do
    if Map.get(user, :patreon_linked) do
      expires_in_date = user.patreon_expires_in
      seven_days_before_today = Timex.shift(Timex.today, days: -7)

      # check if date is already expired
      if Timex.after?(Timex.now, expires_in_date) do
      create_patreon_access(false, false, nil)

      # if not expired check if it should be validated
      else
        # TODO: 90% sure this works.
        if Timex.after?(seven_days_before_today, expires_in_date) do
          refresh_user_patreon_information(host, user)

          # I need to fetch it again, in case the token has changed
          refreshed_user = user |> Account.get_user_pow!()
          check_patreon_tier(refreshed_user)
        else
          check_patreon_tier(user)
        end
      end
    else
      create_patreon_access(false, false, nil)
    end
  end

  defp refresh_user_patreon_information(host, user) do
    base_url = generate_base_url(host)
    mp =
      Multipart.new
      |> Multipart.add_field("grant_type", "refresh_token")
      |> Multipart.add_field("client_id", System.get_env("PATREON_CLIENT_KEY"))
      |> Multipart.add_field("client_secret", System.get_env("PATREON_SECRET_KEY"))
      |> Multipart.add_field("refresh_token", user.patreon_refresh_token)
      # |> Multipart.add_field("access_token", user.patreon_access_token) # this isn't necessary, at all.

    { :ok, response } = post("https://www.patreon.com/api/oauth2/token", mp, headers: [{"content-type", "x-www-form-urlencoded"}])
    body = Jason.decode!(response.body)

    # IO.inspect user.patreon_refresh_token
    # IO.inspect "refresh_user_patreon_information"
    # IO.inspect body

    auth_client = auth_api_client(body["access_token"])
    identity_url = "identity?include=memberships&fields%5Buser%5D=about,created,email,first_name,full_name,image_url,last_name,social_connections,thumb_url,url,vanity"

    { :ok, identityResponse } = auth_client |> get(identity_url)
    identity_body = Jason.decode!(identityResponse.body)

    update_user_information(user, identity_body, body)
  end

  defp check_patreon_tier(user) do
    members_url = "members/#{user.patreon_user_id}?include=address,currently_entitled_tiers,user&fields%5Bmember%5D=full_name,is_follower,email,last_charge_date,last_charge_status,lifetime_support_cents,patron_status,currently_entitled_amount_cents,pledge_relationship_start,will_pay_amount_cents&fields%5Btier%5D=title,amount_cents,description,created_at,url,image_url&fields%5Buser%5D=full_name,hide_pledges"
    # campaign_members_url = "campaigns/2462972/members?include=currently_entitled_tiers&fields%5Bmember%5D=email,patron_status,last_charge_status"
    # IO.inspect "check_patreon_tier"
    # IO.inspect user
    auth_client = auth_api_client(user.patreon_access_token)

    case auth_client |> get(members_url) do
      { :ok, members_response } ->
        members_body = Jason.decode!(members_response.body)

        if not Map.has_key?(members_body, "errors") do
          # IO.inspect "members_body"
          # IO.inspect members_body

          tier_id =
            case members_body["data"]["relationships"]["currently_entitled_tiers"]["data"] do
              nil -> nil
              [] -> nil
              _ -> members_body["data"]["relationships"]["currently_entitled_tiers"]["data"] |> hd() |> Map.get("id")
            end

            # IO.inspect tier_id
            # IO.inspect members_body["included"]
          tier =
            case members_body["included"] do
              nil -> []
              _ -> members_body["included"] |> Enum.find(fn(member) -> member["id"] == tier_id end)
            end

            # IO.inspect tier
          # last_charge_status = members_body["data"]["attributes"]["last_charge_status"]
          patron_status = members_body["data"]["attributes"]["patron_status"]
          create_patreon_access(false, patron_status == "active_patron", tier)
        else
          create_patreon_access(false, false, nil)
        end

      {:error, _error} ->
        IO.inspect "Patreon offline"
        create_patreon_access(false, false, nil)
    end
  end

  defp create_patreon_access(token_expired, is_valid_patron, tier) do
    %{
      token_expired: token_expired,
      is_valid_patron: is_valid_patron,
      tier_access_list: tier_access_list(token_expired, is_valid_patron, tier),
      tier: tier,
    }
  end

  defp tier_access_list(token_expired, is_valid_patron, tier) do
    if (not token_expired and is_valid_patron) do
      case tier.amount_cents do
        100 -> create_tier_access([], tier)
        500 -> create_tier_access([], tier)
        1000 -> create_tier_access([:nfd_bible_access], tier)
        1500 -> create_tier_access([:ebooks_access], tier)
        2500 -> create_tier_access([:ebooks_access, :courses_access, :coaching_access], tier)
        5000 -> create_tier_access([:ebooks_access, :courses_access, :coaching_access], tier)
        10000 -> create_tier_access([:ebooks_access, :courses_access, :coaching_access], tier)
        15000 -> create_tier_access([:ebooks_access, :courses_access, :coaching_access], tier)
        _ -> []
      end
    else
      %{}
    end
  end

  defp create_tier_access(access_list, tier) do
    Enum.reduce(access_list, %{}, fn access_item, acc ->
      Map.put(acc, access_item, true)
    end)
  end

  def generate_relevant_patreon_auth_url(host) do
    base_url = generate_base_url(host)
    authorize_patreon_url = "https://www.patreon.com/oauth2/authorize"
    scope = "campaigns%20identity%20campaigns.members%20identity.memberships"

    "#{authorize_patreon_url}?response_type=code&scope=#{scope}&client_id=#{System.get_env("PATREON_CLIENT_KEY")}&redirect_uri=#{base_url}/validate_patreon"
  end
end


# defmodule PatreonAccess do
#   defstruct first_name: "", last_name: "", age: nil

#   def has_discount?(person) do
#     person.age != nil && person.age < 18
#   end

#   def full_name(person) do
#     "#{person.first_name} #{person.last_name}"
#   end
# end
