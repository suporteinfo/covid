module DataBridge
  class WebServiceBase < DataBridge::Base

    protected
    def get_token token_path, response_param = 'access_token'
      return @token if !@token.nil?

      begin
        response = JSON.parse(RestClient.post get_address(token_path, {}, false), {
          username: connection_data[:username], password: connection_data[:password],
          refresh_token: '', grant_type: 'password'
        }.to_json, content_type: :json, accept: :json)

        @token = response[response_param]
      rescue
        @token = nil
      end
    end

    def request_api path, params = {}, payload = {}, headers = {}, options = {}
      options = { http_method: :post, payload_processor: :to_json }.merge(options)
      print "#{options[:http_method].upcase} #{filter_address(get_address(path, params), params)}..."

      if options.has_key?(:token)
        self.get_token(options[:token])
        headers = headers.merge({ 'Authorization' => "Bearer #{@token}" })

        puts "\nToken: #{@token.to_s.first(5)}***..." if Rails.env.development?
      end

      if Rails.env.development? && !payload.blank?
        puts "\nPayload: " + ('-' * 50)
        puts JSON.pretty_generate(payload)
      end

      if Rails.env.development? && !headers.blank?
        puts "\nHeaders: " + ('-' * 50)
        puts JSON.pretty_generate(headers)
      end

      begin
        self.raw_data = RestClient::Request.execute(
          method: options[:http_method], url: get_address(path, params), payload: payload.try(options[:payload_processor]),
          headers: { 'Content-Type' => 'application/json' }.merge(headers)
        )
      rescue => e
        puts " [ ERROR ]"
        Rails.logger.fatal("Error to post data: #{e.message}")
        self.raw_data, self.data = 0, nil
      end
      puts " [ DONE ]"

      if block_given?
        self.raw_data = yield(self.raw_data)
      end

      process_json
      self.raw_data = nil if self.raw_data != 0
    end

    def process_json
      return unless self.raw_data.kind_of?(String)
      self.data = JSON.parse(self.raw_data)

      if Rails.env.development?
        puts 'Response: ' + ('-' * 50)
        puts JSON.pretty_generate(self.data)
      end
    end

    def url_encode data
      CGI::escape(data.to_s)
    end

    def valid_data?
      !self.data.blank?
    end

    def dynamic_get api_path, params, request_mapping, response_mapping, single_result = false
      params = self.default_params(params, request_mapping)

      self.api_get(api_path, params)
      self.dynamic_process_results(response_mapping)

      self.data = nil if Rails.env.production?
      return single_result ? self.results.try(:first) : self.results
    end

    def default_params params = {}, keys = []
      keys.map{ |key| [key.to_sym, (params.has_key?(key.to_sym) ? params[key.to_sym] : '')] }.to_h
    end

    def get_address path, params = {}, with_base_path = true
      params = {} unless params.kind_of?(Hash)
      return "#{get_host(with_base_path)}#{path}" + (params.empty? ? '' : '?') + params.to_query
    end

    def filter_address address, params = {}
      return address if Rails.env.development?

      %w(password).each do |filterable|
        address.gsub!(params[filterable.to_sym], '[FILTERED]') if params.has_key?(filterable.to_sym)
      end

      return address
    end

    def get_host with_base_path = true
      port = (!connection_data[:port].blank? && ![80, 443].include?(connection_data[:port]) ? ":#{connection_data[:port]}" : '')

      return "http#{(connection_data[:use_ssl].to_s == 'true' ? 's' : '')}://#{connection_data[:hostname]}#{port}#{connection_data[:base_path] if with_base_path}"
    end

  end
end
