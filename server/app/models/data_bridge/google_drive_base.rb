# frozen_string_literal: true

module DataBridge
  class GoogleDriveBase < DataBridge::Base
    attr_accessor :session

    def start_session(config)
      self.session = GoogleDrive::Session.from_service_account_key(config)
      self
    end

    def get_spreadsheet(key)
      session.spreadsheet_by_key(key)
    end

    def get_data_from_google_drive(spreadsheet_key)
      start_session('6b163b4ba5828a7bac27f8b068d90bb60ea71aca')
      get_spreadsheet(spreadsheet_key)
    end
  end
end
