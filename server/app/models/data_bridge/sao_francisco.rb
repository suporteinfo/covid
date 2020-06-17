module DataBridge
  class SaoFrancisco < DataBridge::WebServiceBase

    def connection_data
      Rails.application.credentials.sao_francisco_connection
    end

    def get_data
      headers = {
        'Content-Type' => 'application/json'
      }

      self.request_api( 'leitos-sf', {}, {}, headers, { http_method: :get } )
      process_beds

      self.data = nil if Rails.env.production?
      return self
    end

    protected

    def process_beds
      self.results = []
      return unless self.valid_data?

      self.data['dados'].each do |r|
        hospital_slug = get_hospital_slug(r['gsx$identificadorhospital']['$t'])
        next if hospital_slug != 'hospital-sao-francisco'

        self.results << DataBridge::InternalObject.new(
          hospital_slug:    hospital_slug,
          status:           get_status(r['gsx$status']['$t']),
          bed_type:         get_bed_type(r['gsx$tipodeleito']['$t'].to_s.strip.parameterize.gsub('-19', '')),
          slug:             r['gsx$identificadorleito']['$t'].parameterize,
          using_ventilator: r['gsx$usorespirador']['$t'].to_s.downcase == 'sim',
        )
      end
    end

    def get_hospital_slug hospital_slug
      return hospital_slug.to_s.parameterize
    end

  end
end
