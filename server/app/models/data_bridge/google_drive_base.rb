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
  end
end
