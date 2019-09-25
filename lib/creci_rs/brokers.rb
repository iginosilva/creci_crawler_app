require 'open-uri'

module CreciRs
  class Brokers
    class << self
      def fetch_brokers
        initial_url = 'http://creci-rs.gov.br/site/poder_judiciario.php'
        initial_page = parse_page(initial_url)

        cities =
          initial_page.search('form#pesquisa_corretor select#cidade option').
            map { |city| { id: city.attr('value'), name: city.text } }.
            reject { |city| city[:id].blank? }

        brokers = []
        cities.each do |city|
          url = "http://creci-rs.gov.br/site/poder_judiciario_man.php?nr_conselho=&cidade=#{city[:id]}"
          page = parse_page(url)

          puts "Iniciando cidade #{city[:name]}"
          puts '-----------------------'
          puts '-----------------------'
          puts '-----------------------'

          page.search('#accordion .panel.panel-default').each do |info_box|
            address =
              info_box.search('.panel-body').at('b:contains("Endereço:")').
                next.text.squish
            phones =
              info_box.search('.panel-body').at('b:contains("Telefone:")').
                next.text.squish.scan(/\(\d+\) \d+/)
            phone1 = phones[0]
            phone2 = phones[1] if phones[1].present?
            
            broker = {
              name: info_box.search('h4 a').text.squish.scan(/ - \w.+/)[0].tr('-', '').squish,
              email: info_box.search('.panel-body').at('b:contains("E-mail:")').next.text.squish,
              phone1: phone1,
              phone2: phone2,
              address: address,
              city: city[:name],
              state: 'RS',
            }

            puts "Capturado broker | #{broker}"
            puts '-----------------------'
            puts '-----------------------'
            puts '-----------------------'

            brokers << broker
          end
        end

        create_spreadsheet(brokers)
      end

      def parse_page(url)
        Nokogiri::HTML(open(url))
      end

      def create_spreadsheet(brokers)
        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new
        broker_sheet = book.create_worksheet
        broker_sheet.row(0).concat %w{Nome Email Telefone1 Telefone2 Endereço Cidade Estado}

        brokers.each_with_index do |broker, index|
          broker_sheet.row(index + 1).push broker[:name], broker[:email], broker[:phone1], broker[:phone2], broker[:address], broker[:city], broker[:state]
        end
        book.write '/home/igino/Área de Trabalho/creci_rs_corretores.xls'
      end
    end
  end
end
