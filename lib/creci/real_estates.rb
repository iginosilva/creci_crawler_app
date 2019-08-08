module Creci
  class RealEstates
    def initialize
      @asp_net_session_cookie = '5nsysuginopp5kt3ibcqjt3m'
    end

    def fetch_real_estates
      initial_search_page = initial_page
      url_total_pages = initial_search_page.search('div.pagination.row ol li.list-inline-item a')[-2].attr('href')
      total_pages = grab_total_page_number(url_total_pages)

      @last_page = RealEstate.last.try(:page_control).present? ? RealEstate.last.page_control.page.to_i : 0
      (@last_page..total_pages).each do |page|
        puts "Iniciando busca na página #{page}"
        puts '--------------------------'
        puts '--------------------------'
        puts '--------------------------'

        search_page = real_estate_list_by_page(page)
        @real_estate_not_found = search_page.at('p:contains("Não foram encontradas imobiliárias")').present? ? true : false
        if @real_estate_not_found.present?
          puts "Nenhuma imobiliária encontrada na página #{page} | Ir para próxima página - #{@real_estate_not_found}"
          puts '--------------------------'
          puts '--------------------------'
          puts '--------------------------'
          return
        end
        @page_control = PageControl.where({ page: page }).first_or_initialize
        @page_control.save!
        
        search_page.search('.cidadao.listadeimobiliarias .row .col-lg-4.col-md-3.mt-1.mb-1').each do |real_estate|
          real_estate_creci = real_estate.search('div span')[0].text.squish
          real_estate_name = real_estate.search('h6').text.squish

          real_estate_page = real_estate_page(real_estate_creci)
          if real_estate_page.present?
            puts "Iniciando busca de email da imobiliária CRECI #{real_estate_creci} | Página #{page}"
            puts '--------------------------'
            puts '--------------------------'
            puts '--------------------------'
          end

          puts "Imobiliária #{real_estate_creci} com telefone na página #{page}" if real_estate_page.at('label:contains("Telefone")')
          puts "Imobiliária #{real_estate_creci} com telefone na página #{page}" if real_estate_page.at('label:contains("Phone")')
          puts "Imobiliária #{real_estate_creci} com telefone na página #{page}" if real_estate_page.at('label:contains("Celular")')
          puts "Imobiliária #{real_estate_creci} com telefone na página #{page}" if real_estate_page.at('label:contains("Contato")')

          real_estate_address_line = real_estate_page.at('label:contains("Endereço")')

          if real_estate_address_line.present?
            real_estate_address = real_estate_page.at('label:contains("Endereço")').parent.parent.search('span').text.squish
            real_estate_uf = real_estate_address.scan(/\w+$/)[0]
            real_estate_city = real_estate_address.scan(/, .*? (?=\w+$)/)[0].tr(',', '').squish
            real_estate_neighborhood = real_estate_address.scan(/Bairro .*?,/)[0].gsub(/Bairro/, '').tr(',', '').squish
          end

          if real_estate_page.at('label:contains("E-Mail")').present?
            real_estate_email = real_estate_page.at('label:contains("E-Mail")').parent.parent.search('span').text.squish
          end

          real_estate_situation = real_estate_page.at('label:contains("Status")').parent.parent.search('span').text.squish
          
          if real_estate_page.search('div.mt-5 div span')[0].present?
            real_estate_technical_manager_name = real_estate_page.search('div.mt-5 div span')[0].text.squish
          end

          if real_estate_page.search('div.mt-5 div span')[1].present?
            real_estate_technical_manager_creci = real_estate_page.search('div.mt-5 div span')[1].text.squish
          end

          @real_estate = RealEstate.find_or_initialize_by(name: real_estate_name, email: real_estate_email, address: real_estate_address, neighborhood: real_estate_neighborhood, city: real_estate_city, state: real_estate_uf, creci: real_estate_creci, situation: real_estate_situation, technical_manager_name: real_estate_technical_manager_name, technical_manager_creci: real_estate_technical_manager_creci)

          @real_estate.page_control_id = @page_control.id
          @real_estate.save!
        end
      end
    end

    def real_estate_page(creci_number)
      request = `curl 'https://www.crecisp.gov.br/cidadao/detalhesimobiliaria' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: https://www.crecisp.gov.br' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://www.crecisp.gov.br/cidadao/listadeimobiliarias?page=9&IsFinding=True' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' -H "Cookie: _ga=GA1.3.259931362.1564599703; _gid=GA1.3.836408227.1564599703; ASP.NET_SessionId=#{@asp_net_session_cookie}; _gat=1" --data "registerNumber=#{creci_number}" --compressed`
      parse_page(request)
    end

    def real_estate_list_by_page(page)
      request = `curl "https://www.crecisp.gov.br/cidadao/listadeimobiliarias?page=#{page}&IsFinding=True" -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://www.crecisp.gov.br/cidadao/listadeimobiliarias?IsFinding=True' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' -H "Cookie: _ga=GA1.3.259931362.1564599703; _gid=GA1.3.836408227.1564599703; ASP.NET_SessionId=#{@asp_net_session_cookie}" --compressed`
      parse_page(request)
    end

    def initial_page
      request = `curl 'https://www.crecisp.gov.br/cidadao/listadeimobiliarias?IsFinding=True' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://www.crecisp.gov.br/cidadao/buscarporimobiliaria' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' -H "Cookie: _ga=GA1.3.259931362.1564599703; _gid=GA1.3.836408227.1564599703; ASP.NET_SessionId=#{@asp_net_session_cookie}; _gat=1" --compressed`
      parse_page(request)
    end

    def grab_total_page_number(text)
      text.scan(/page=\d+/)[0].tr('page=', '').to_i + 2
    end

    def parse_page(page)
      Nokogiri::HTML(page)
    end

    def create_spreadsheet
      real_estate_list = RealEstate.all.distinct.order(name: :asc)
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet::Workbook.new
      real_estate_sheet = book.create_worksheet
      real_estate_sheet.row(0).concat %w{Nome Email Endereço Bairro Cidade Estado Situação}

      real_estate_list.each_with_index do |real_estate, index|
        real_estate_sheet.row(index + 1).push real_estate[:name], real_estate[:email], real_estate[:address], real_estate[:neighborhood],
        real_estate[:city], real_estate[:state], real_estate[:situation]
      end
      book.write '/home/igino/Área de Trabalho/imobiliarias_creci.xls'
    end
  end
end