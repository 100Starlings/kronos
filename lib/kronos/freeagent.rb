module Kronos
  # Freeagent
  # a naive client for freeagent
  class Freeagent
    attr_reader :client

    def initialize
      @access_token = ENV["FREEAGENT_ACCESS_TOKEN"]
      @refresh_token = ENV["FREEAGENT_REFRESH_TOKEN"]
      @client = setup_client
    end

    def timeslips(from_date, to_date)
      timeslips_url = "v2/timeslips?from_date=#{from_date}&to_date=#{to_date}"
      paginate_through(timeslips_url)
        .map(&:timeslips)
        .flatten
    end

    private

    def paginate_through(url)
      fail "provide the url of the first page" unless url
      pages = []
      while url
        puts "fetching #{url}"
        response = client.get(url)
        fail "Something went wrong: #{response.body}" unless response.success?
        url = next_page_url(response)

        page_json = JSON.parse(response.body)
        pages << Hashie::Mash.new(page_json)
      end

      pages
    end

    def setup_client
      c = Hurley::Client.new ENV["FREEAGENT_API_URL"]
      c.header[:authorization] = "Bearer #{@access_token}"
      c.header[:accept] = "application/json"
      c
    end

    def next_page_url(response)
      puts "Extracting next page from:\n#{response.header}"
      link_header = response.header["Link"]

      links = link_header.split(",")
      next_link = links.find { |l| l.match(/; rel='next'/) } if links
      next_link.match(%r{<https://api.freeagent.com/([^>]+)>;})[1] if next_link
    end
  end
end
