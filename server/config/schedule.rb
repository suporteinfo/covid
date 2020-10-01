# frozen_string_literal: true

set :chronic_options, hours24: true

every 1.day, at: ['0:20', '6:24', '13:24', '19:24'] do
  runner 'DataBridge::Estadual.new.get_data.save!'
end

every 1.day, at: ['0:25', '6:29', '13:29', '19:29'] do
  runner 'DataBridge::Maternidade.new.get_data.save!'
end

every '50 * * * *' do
  runner 'DataBridge::CovidCases::Estadual.new.get_data.save!'
end

every '50 * * * *' do
  runner 'DataBridge::CovidCases::Maternidade.new.get_data.save!'
end
