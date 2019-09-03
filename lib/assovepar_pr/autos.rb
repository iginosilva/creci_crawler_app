require 'open-uri'

module AssoveparPr
  class Autos
    class << self
      def fetch_autos
        autos = []
        (1..6).each do |current_page|
          url = "http://www.assovepar.com.br/associados?search=&page=#{current_page}"
          page = parse_page(url)
          break if page.search('table tbody tr').blank?

          puts "Iniciando página #{current_page}"
          puts '-----------------------'
          puts '-----------------------'
          puts '-----------------------'

          page.search('table tbody tr').each do |auto_box|
            address = auto_box.search('p.street').text
            cep = auto_box.search('p.cep').text.squish

            auto = {
              name: auto_box.search('p.nome').text,
              email: auto_box.search('p.email').text,
              phone: auto_box.search('p.phone').text,
              address: "#{address} / #{cep}",
              city: auto_box.search('p.city-state').text.scan(/^.* -/)[0].tr('-', '').squish,
              state: 'PR',
              site: auto_box.search('p.website').text,
            }

            puts "Capturado | #{auto}"
            puts '-----------------------'
            puts '-----------------------'
            puts '-----------------------'

            autos << auto
          end
        end
        create_spreadsheet(autos)
      end

      def parse_page(url)
        Nokogiri::HTML(open(url))
      end

      def create_spreadsheet(autos)
        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new
        auto_sheet = book.create_worksheet
        auto_sheet.row(0).concat %w{Nome Email Telefone Endereço Cidade Estado Site}

        autos.each_with_index do |auto, index|
          auto_sheet.row(index + 1).push auto[:name], auto[:email], auto[:phone], auto[:address], auto[:city], auto[:state], auto[:site]
        end
        book.write '/home/igino/Área de Trabalho/assovepar_autos_pr.xls'
      end
    end
  end
end
