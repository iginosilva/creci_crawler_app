require 'open-uri'

module GuiaDeSampa
  class Autos
    class << self
      def fetch_autos
        autos = []
        (1..4).each do |current_page|
          byebug
          url = "https://www.guiadesampa.com.br/depto.asp?depto=concessionarias&pag=#{current_page}&mul=1"
          page = parse_page(url)

          break if page.search('#geral #meio #conteudo #interna .quadrado').blank?

          puts "Iniciando página #{current_page}"
          puts '-----------------------'
          puts '-----------------------'
          puts '-----------------------'

          page.search('#geral #meio #conteudo #interna .quadrado').each do |info_box|
            address = info_box.search('.dados2 .endereco2 p').children[1].text
            address_comp = info_box.search('.dados2 .bairro2 p').text.squish
            neighborhood = address_comp.scan(/^.*? -/)[0].tr('-', '').squish
            city = address_comp.scan(/- .*? \//)[0].tr('-/', '').squish
            state = address_comp.scan(/(?! \/ )\w+$/)[0]

            auto = {
              name: info_box.search('h5 .nomefantasia strong').text,
              email: info_box.search('.dados2 .siteemail2 .email2 p a').text,
              phone: info_box.search('.dados2 .fonefax2 .telefone2 p').children[1].text,
              address: address,
              neighborhood: neighborhood,
              city: city,
              state: state,
              site: info_box.search('.dados2 .siteemail2 .site2 p a').text,
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
        auto_sheet.row(0).concat %w{Nome Email Telefone Endereço Bairro Cidade Estado Site}

        autos.each_with_index do |auto, index|
          auto_sheet.row(index + 1).push auto[:name], auto[:email], auto[:phone], auto[:address], auto[:neighborhood], auto[:city], auto[:state], auto[:site]
        end
        book.write '/home/igino/Área de Trabalho/guia_de_sampa_autos.xls'
      end
    end
  end
end
