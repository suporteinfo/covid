class CovidCase < ApplicationRecord
  belongs_to :city

  def to_json
    {
      total: total,
      deaths: deaths,
      cureds: cureds
    }
  end

  def self.populate_with_api
    city = (City.find_by slug: 'ribeirao-preto').id
    covid = self.get_data_from_api
    covid[:results].each do |data|
      if (CovidCase.where("reference_date = :reference_date AND city_id = :city", {reference_date: data[:date], city: city}).count < 1)
        CovidCase.find_or_initialize_by(city_id: city, reference_date: data[:date]).update(total: data[:confirmed], deaths: data[:deaths])
      end
    end
  end

  def self.get_data_from_api
    data = JSON.parse(RestClient::Resource.new('https://brasil.io/api/dataset/covid19/caso/data?city=Ribeir%C3%A3o%20Preto').get.body).with_indifferent_access
  end

  def self.google_drive_sheets
    row = nil
    city = City.find_by_slug('ribeirao-preto')
    reference_date = Date.today - 1.day
    spreadsheet = DataBridge::GoogleDriveBase.new.start_session('')
    spreadsheet = spreadsheet.get_spreadsheet(Rails.application.credentials.spreadsheet_key)
    worksheet = spreadsheet.worksheets[1]
    
    worksheet.num_rows.downto(1).each do |i|
      break row = i if worksheet[i, 1] == I18n.l(reference_date)
    end

    return populate_with_api unless row

    CovidCase.find_or_initialize_by(city: city, reference_date: reference_date).update(total: worksheet[row, 4], deaths: worksheet[row, 7])
  end
end
