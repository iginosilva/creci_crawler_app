require 'open-uri'

module SecoviRio
  class RealEstates
    class << self
      def fetch_real_estates
        real_estates = []
        url = 'https://www.secovirio.com.br/associe-se/empresas-associadas/'
        page = parse_page(url)
        
        page.search('p:contains("E-mail:")').each do |real_info|

          next if real_info.text.gsub(/\n/, '') == "CONHEÇA AS EMPRESAS ASSOCIADAS:"

          real_estate = {
            name: nil,
            email: nil,
            phone: nil,
            address: nil,
            neighborhood: nil,
            city: 'Rio de Janeiro',
            state: 'RJ',
            site: nil,
          }

          real_data = real_info.children.map { |data| data.text.gsub(/\n/, '') }

          no_title = real_data[0].include?('Site')

          name = no_title.present? ? real_info.previous.previous.text : real_data[0]
          email = real_data.select { |data| data.include?('@') }[0]
          phone = real_data.select { |data| data.include?('Telefone') }[0]
          address = real_data.select { |data| data.include?('Endereço') }[0]
          neighborhood = real_data.select { |data| data.include?('Bairro') }[0].scan(/(?=:).*/)[0].squish.tr(':', '')
          site = real_data.select { |data| data.include?('www.') }[0]

          next if email.blank?

          real_estate[:name] = name if name.present?

          puts "Iniciando imobiliária | #{real_estate[:name]}"
          puts '-----------------------'
          puts '-----------------------'
          puts '-----------------------'

          real_estate[:site] = site.squish if site.present?

          real_estate[:address] = address.scan(/(?=:).*/)[0].squish.tr(':', '') if address.present?

          only_neighborhood = neighborhood.scan(/^.*? [-–]/)[0].blank?
          if only_neighborhood
            real_estate[:neighborhood] = neighborhood
          else
            real_estate[:neighborhood] = neighborhood.scan(/^.*? [-–]/)[0].tr('–-', '').squish
          end    

          real_estate[:phone] = phone.scan(/(?=:).*/)[0].squish.tr(':', '') if phone.present?

          if email.include?('Email') || email.include?('E-mail')
            real_estate[:email] = email.scan(/(?=:).*/)[0].squish.tr(':', '')
          else
            real_estate[:email] = email
          end

          puts "Capturado | #{real_estate}"
          puts '-----------------------'
          puts '-----------------------'
          puts '-----------------------'

          real_estates << real_estate
        end

        create_spreadsheet(real_estates)
      end

      def parse_page(url)
        Nokogiri::HTML(open(url))
      end

      def create_spreadsheet(real_estates)
        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new
        real_estate_sheet = book.create_worksheet
        real_estate_sheet.row(0).concat %w{Nome E-mail Telefone Endereço Bairro Cidade Estado Site}

        real_estates.each_with_index do |real_estate, index|
          real_estate_sheet.row(index + 1).push real_estate[:name], real_estate[:email], real_estate[:phone], real_estate[:address], real_estate[:neighborhood], real_estate[:city], real_estate[:state], real_estate[:site]
        end

        book.write '/home/igino/Área de Trabalho/imobiliarias_secovi_rio_rj.xls'
      end
    end
  end
end
