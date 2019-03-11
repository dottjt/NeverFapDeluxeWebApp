defmodule NfdWeb.PowMailer do
  use Pow.Phoenix.Mailer
  use Swoosh.Mailer, otp_app: :nfd

  import Swoosh.Email

  require Logger

  def cast(%{user: user, subject: subject, text: text, html: html}) do
    %Swoosh.Email{} 
      |> to({user.email, user.email}) # user.email
      |> from({"NeverFap Deluxe", "neverfapdeluxe@gmail.com"})
      |> subject(subject)
      |> html_body(html)
      |> text_body(text)
  end

  def process(email) do
    IO.inspect(email)
    Nfd.SwooshMailer.deliver(email)
    Logger.debug("E-mail sent")
  end  
end
