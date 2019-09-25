module Creci
  class Brokers
    def initialize
      @asp_net_session_cookie = 'agwnuckco5rhcveu3xpb5q4i'
    end

    def fetch_brokers
      initial_search_page = initial_page
      if initial_search_page.search('div.pagination.row ol li.list-inline-item a').present?
        url_total_pages = initial_search_page.search('div.pagination.row ol li.list-inline-item a')[-2].attr('href')
      end

      total_pages = url_total_pages.present? ? grab_total_page_number(url_total_pages) : 0

      @last_page = Broker.last.try(:page_control).present? ? Broker.last.page_control.page.to_i : 0
      (@last_page..total_pages).each do |page|
        puts "Iniciando busca na página #{page}"
        puts '--------------------------'
        puts '--------------------------'
        puts '--------------------------'

        search_page = broker_list_by_page(page)
        @broker_not_found = search_page.at('p:contains("Não foram encontrados corretores")').present?
        if @broker_not_found.present?
          puts "Nenhum corretor encontrado na página #{page} | Ir para próxima página - #{@broker_not_found}"
          puts '--------------------------'
          puts '--------------------------'
          puts '--------------------------'
        end
        @page_control = PageControl.where({ page: page }).first_or_initialize
        @page_control.save!

        search_page.search('.cidadao.listadecorretores .col-lg-4.broker-details').each do |broker|
          broker_creci = broker.search('div span')[0].text.squish
          broker_name = broker.search('h6').text.squish
          broker_situation = broker.search('div span')[1].text.squish
          unabled_broker_status = ['Cancelado por ordem administrativa', 'Cancelado por falecimento', 'Cancelado a pedido do titular']

          next if unabled_broker_status.include?(broker_situation)

          page_broker = page_broker(broker_creci)
          if page_broker.present?
            puts "Iniciando busca de email do broker CRECI #{broker_creci} | Página #{page}"
            puts '--------------------------'
            puts '--------------------------'
            puts '--------------------------'
          end

          next if page_broker.at('label:contains("UF")').blank?

          if page_broker.at('label:contains("E-Mail")').present?
            broker_email = page_broker.at('label:contains("E-Mail")').parent.parent.search('span').text.squish
          end

          if page_broker.at('label:contains("E-Mail Oficial")').present?
            broker_email2 = page_broker.at('label:contains("E-Mail Oficial")').parent.parent.search('span').text.squish
          end

          if page_broker.at('label:contains("Contato(s)")').present?
            phones = page_broker.at('label:contains("Contato(s)")').parent.parent.search('span').text.squish.scan(/\(\d+\) \d+-\d+/)
            broker_phone = phones[0]
            broker_phone2 = phones[1]
          end

          if page_broker.at('label:contains("UF")').present?
            broker_uf = page_broker.at('label:contains("UF")').parent.parent.search('span').text.squish
          end

          if page_broker.at('label:contains("Bairro de Atuação")').present?
            broker_acting_neighborhood = page_broker.at('label:contains("Bairro de Atuação")').parent.parent.search('span').text.squish
          end

          invalid_contacts =
            broker_email.blank? && broker_email2.blank? && broker_phone.blank? && broker_phone2.blank?

          next if invalid_contacts.present?

          @broker = Broker.find_or_initialize_by({
            name: broker_name,
            email: broker_email,
            email2: broker_email2,
            phone: broker_phone,
            phone2: broker_phone2,
            creci: broker_creci,
            acting_neighborhood: broker_acting_neighborhood,
            state: broker_uf,
            situation: broker_situation,
          })

          @broker.page_control_id = @page_control.id
          @broker.save!
        end
      end
    end

    def page_broker(creci_number)
      request = `curl 'https://www.crecisp.gov.br/cidadao/corretordetalhes' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Origin: https://www.crecisp.gov.br' -H 'Upgrade-Insecure-Requests: 1' -H 'Content-Type: application/x-www-form-urlencoded' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://www.crecisp.gov.br/cidadao/listadecorretores?page=0&firstLetter=A' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' -H "Cookie: _ga=GA1.3.259931362.1564599703; _gid=GA1.3.836408227.1564599703; ASP.NET_SessionId=#{@asp_net_session_cookie}" --data "registerNumber=#{creci_number}" --compressed`
      parse_page(request)
    end

    def broker_list_by_page(page)
      request = `curl "https://www.crecisp.gov.br/cidadao/listadecorretores?page=#{page}" -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' -H "Cookie: _ga=GA1.3.259931362.1564599703; _gid=GA1.3.836408227.1564599703; ASP.NET_SessionId=#{@asp_net_session_cookie}" --compressed`
      parse_page(request)
    end

    def initial_page
      request = `curl 'https://www.crecisp.gov.br/cidadao/listadecorretores' -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.100 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'Referer: https://www.crecisp.gov.br/cidadao/buscaporcorretores' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7' -H "Cookie: _ga=GA1.3.259931362.1564599703; _gid=GA1.3.836408227.1564599703; ASP.NET_SessionId=#{@asp_net_session_cookie}" --compressed`
      parse_page(request)
    end

    def grab_total_page_number(text)
      text.scan(/page=\d+/)[0].tr('page=', '').to_i + 1
    end

    def parse_page(page)
      Nokogiri::HTML(page)
    end

    def create_spreadsheet
      broker_list = Broker.all.distinct.order(name: :asc)
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet::Workbook.new
      brokers_sheet = book.create_worksheet
      brokers_sheet.row(0).concat %w{Nome Email Email2 Telefone Telefone2 Bairro Estado Situação}

      broker_list.each_with_index do |broker, index|
        brokers_sheet.row(index + 1).push broker[:name], broker[:email], broker[:email2], broker[:phone], broker[:phone2], broker[:acting_neighborhood], broker[:state], broker[:situation]
      end
      book.write '/home/igino/Área de Trabalho/corretores_creci.xls'
    end
  end
end
