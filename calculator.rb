require 'active_support/all'
require 'watir' # Crawler
require 'colorize'
require 'pry' # Ruby REPL
require 'rb-readline' # Ruby IRB

# require 'awesome_print' # Console output

class Array
  def to_table
    column_sizes = reduce([]) do |lengths, row|
      row.each_with_index.map { |iterand, index| [lengths[index] || 0, iterand.to_s.length].max }
    end
    puts head = '-'.light_blue * (column_sizes.inject(&:+) + (3 * column_sizes.count) + 1)
    each do |row|
      row = row.fill(nil, row.size..(column_sizes.size - 1))
      row = row.each_with_index.map { |v, i| v.to_s + ' ' * (column_sizes[i] - v.to_s.length) }
      puts '| ' + row.join(' | ') + ' |'
    end
    puts head
  end
end

def formatted_duration(hours_with_minutes)
  return '***' if hours_with_minutes == Float::INFINITY
  hours = hours_with_minutes.to_i
  minutes = (hours_with_minutes - hours_with_minutes.to_i) * 60
  "#{hours}h #{minutes.ceil}min"
end

def is_ooo?(date)
  date.saturday? || date.sunday? || is_holiday?(date) || is_vacation?(date) || is_dayoff?(date)
end

def is_dayoff?(date)
  CONFIG[:dayoffs]&.include?(date.strftime('%d.%m.%Y'))
end

def is_holiday?(date)
  CONFIG[:holidays]&.include?(date.strftime('%d.%m.%Y'))
end

def is_vacation?(date)
  CONFIG[:vacations]&.include?(date.strftime('%d.%m.%Y'))
end

CONFIG = YAML::load_file('config.yml').with_indifferent_access

started_this_month = Date.today.mday >= CONFIG[:start_day]
start_date = Date.today - Date.today.mday + CONFIG[:start_day]
end_date = Date.today - Date.today.mday + CONFIG[:end_day] + 1.month
unless started_this_month
  start_date -= 1.month
  end_date -= 1.month
end

empty_calendar = (start_date.cweek..end_date.cweek).each_with_object({}) do |w, memo|
  memo[w] = Array.new(7, '-'.green)
end

calend = (start_date..end_date).to_a.each_with_object(empty_calendar) do |d, calendar|
  daycolor = is_ooo?(d) ? :red : :blue
  daycolor = :yellow if d == Date.today
  wd = (d.wday + 6) % 7
  calendar[d.cweek][wd] = d.day.to_s.send(daycolor)
end

puts calend.values.to_table

work_days = (start_date..end_date).to_a.reject { |k| is_ooo?(k) }.count
worked_days = (start_date..Date.today).to_a.reject { |k| is_ooo?(k) }.count
days_left = work_days - worked_days
stat_url = "app.hubstaff.com/reports/#{CONFIG[:company_id]}/my/time_and_activities?date=#{start_date.strftime('%F')}&date_end=#{end_date.strftime('%F')}"

browser = Watir::Browser.new(
  :chrome,
  switches: %w[
    --ignore-certificate-errors --disable-popup-blocking --disable-translate
    --disable-notifications --start-maximized --disable-gpu --headless
  ]
)
browser.goto(CONFIG[:login_url])
browser.text_field(id: 'user_email').set CONFIG[:username]
browser.text_field(id: 'user_password').set CONFIG[:password]
browser.button(text: 'Log in').click

browser.goto(stat_url)

hours_earned_arr = browser.div(class: 'report-rollup-value').text.split(':').map(&:to_f)
hours_earned = hours_earned_arr[0] + hours_earned_arr[1] / 60 + hours_earned_arr[2] / 3600
hours_planned = CONFIG[:hours_a_day] * work_days
hours_to_earn = hours_planned - hours_earned
current_avarage = hours_earned / worked_days.to_f
future_avarage = hours_to_earn / days_left.to_f

puts "#{'You have earned'.red} #{formatted_duration(hours_earned)} hours during #{worked_days} days(including today)"
puts "#{'Current avarage'.red}: #{formatted_duration(current_avarage)}"
puts '-'.light_blue * 80
puts "#{'Hours_planned'.blue} = #{hours_planned}"
puts "#{'You have to earn more'.green} #{formatted_duration(hours_planned - hours_earned)}!"
puts "#{'Days left'.red}: #{days_left} with avarage #{formatted_duration(future_avarage)} "#{@movie.duration/60}h #{@movie.duration % 60}min"

puts '@'.light_blue * 80
puts 'DUMAJ!'.red
puts '@'.light_blue * 80
