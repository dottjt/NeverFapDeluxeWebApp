defmodule NfdWeb.SevenDayKickstarterScheduler do
  alias Nfd.Account

  def run(count) do
    case count do
      0 -> { "", "" }
      1 -> { "", "" }
      2 -> { "", "" }
      3 -> { "", "" }
      4 -> { "", "" }
      5 -> { "", "" }
      6 -> { "", "" }
      7 -> { "", "" }
    end
  end

  def update(subscriber, day_count) do 
    if (day_count == 7) do
      Account.update_subscriber(subscriber, %{ seven_day_kickstarter_subscribed: false, seven_day_kickstarter_count: 0 })
    else
      incremented_counter = subscriber.seven_day_kickstarter_count + 1
      Account.update_subscriber(subscriber, %{ seven_day_kickstarter_count: incremented_counter })
    end
  end
end