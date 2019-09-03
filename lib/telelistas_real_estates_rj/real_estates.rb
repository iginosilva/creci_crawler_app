require 'open-uri'

module TelelistasRealEstatesRj
  class RealEstates
    class << self
      def fetch_real_estates
        real_estates = []
        (1..90).each do |current_page|
          url = "https://www.telelistas.net/rj/rio+de+janeiro/imobiliarias?pag=#{current_page}"
          page = parse_page(url)
          break if page.at('p:contains("Não foram encontrados")').present?

          puts "Iniciando página #{current_page}"
          puts '-----------------------'
          puts '-----------------------'
          puts '-----------------------'

          page.search('h3.text_resultado_ib').each do |real_box|
            real_page = parse_page(real_box.parent.attr('href'))

            real_estate = {
              name: nil,
              phone: nil,
              address: nil,
            }

            if real_page.search('h1.h3.d-none.d-sm-block').present?
              real_estate[:name] = real_page.search('h1.h3.d-none.d-sm-block').text
            end

            puts "Iniciando imobiliária | #{real_estate[:name]} Página #{current_page}"
            puts '-----------------------'
            puts '-----------------------'
            puts '-----------------------'

            if real_page.search('div#mostrarnumeros h6.mt-2 a').present?
              real_estate[:phone] = real_page.search('div#mostrarnumeros h6.mt-2 a').map { |number| number.text.squish }.join("/")
            end

            if real_page.at('h5:contains("Endereço")').present?
              real_estate[:address] = real_page.at('h5:contains("Endereço")').parent.search('h6').text.squish
            end

            puts "Capturado | #{real_estate}"
            puts '-----------------------'
            puts '-----------------------'
            puts '-----------------------'

            real_estates << real_estate
          end
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
        real_estate_sheet.row(0).concat %w{Nome Telefone Endereço}

        real_estates.each_with_index do |real_estate, index|
          real_estate_sheet.row(index + 1).push real_estate[:name], real_estate[:phone], real_estate[:address]
        end
        book.write '/home/igino/Área de Trabalho/imobiliarias_telelistas_rj.xls'
      end
    end
  end
end