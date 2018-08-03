require 'open-uri'
require 'nokogiri'
require_relative './people'

class ScrapeMp
  def parser
    url = "https://mkrada.gov.ua/content/sklad-deputatskogo-korpusu-mikolaivskoi-miskoi-radi-7-sklikannya.html"
    page = get_page(url)
     page.css('ul.childpages a').each_with_index do |mp, index|
       scrape_mp(mp[:href], mp.text, 5001 + index)
     end
    resigned_mp()
    create_mer()
  end
  def create_mer
    #TODO create mer Sadovoy
    names = %w{Сєнкевич Олександр Федорович}
    People.first_or_create(
        first_name: names[1],
        middle_name: names[2],
        last_name: names[0],
        full_name: names.join(' '),
        deputy_id: 1111,
        okrug: nil,
        photo_url: "https://mkrada.gov.ua/files/368/11_2016/ORL_0139_1.JPG",
        faction: "Позафракційні",
        end_date:  nil,
        created_at: "9999-12-31",
        updated_at: "9999-12-31"
    )
  end
  def get_page(url)
    Nokogiri::HTML(open(url, "User-Agent" => "HTTP_USER_AGENT:Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/534.13 (KHTML, like Gecko) Chrome/9.0.597.47"), nil, 'utf-8')
  end
  def resigned_mp
    names = %w{Омельчук Олександр Андрійович}
    People.first_or_create(
        first_name: names[1],
        middle_name: names[2],
        last_name: names[0],
        full_name: names.join(' '),
        deputy_id: 4999,
        okrug: nil,
        photo_url: "https://mkrada.gov.ua/files/deputati/61.img.jpg",
        faction: "Опозиційний блок",
        end_date:  "2016-12-23",
        created_at: "9999-12-31",
        updated_at: "9999-12-31"
    )
  end
  def scrape_mp(url, mp, rada_id , date_end = nil )
    if date_end.nil?
      date_end = nil
    else
      date_end = Date.parse(date_end,'%d.%m.%Y')
    end
    uri = "https://mkrada.gov.ua" + url
    page_mp= get_page(uri)
    name = mp.strip
    image_html = page_mp.css('.p-content__inner p img')[0][:src]
    image = "https://mkrada.gov.ua" + image_html
    p uri
    p name
    p image
    hash = {}
    page_mp.css('.p-content__inner p').each do |p|
      if p.text[/(Партійність|Партіійність|Член)/]
        hash[:party] = p.text
        next
      elsif p.text[/(Позапартійний|позапартійний)/] or p.text[/(Позапартійна|позапартійна)/]
        hash[:party] = "Позафракційні"
        next
      end
    end
    p hash[:party]
    if hash[:party].include?("Опозиційний блок") or hash[:party].include?("Опозиційний Блок")
       party = "Опозиційний блок"
    elsif hash[:party]=="Позафракційні"
       party = "Позафракційні"
    elsif hash[:party].include?("Солідарність") or  hash[:party].include?("СОЛІДАРНІСТЬ")
       party = "Блок Петра Порошенка"
    elsif hash[:party].include?("САМОПОМІЧ") or hash[:party].include?("Самопоміч")
       party = "Самопоміч"
    elsif hash[:party].include?("Наш край") or hash[:party].include?("Наш Край")
      party = "Наш край"
    else
      raise hash[:party]
    end
    p party

    name_array= name.split(' ')
    people = People.first(
        first_name: name_array[1],
        middle_name: name_array[2],
        last_name: name_array[0],
        full_name: name_array.join(' '),
        photo_url: image,
        faction: party,
    )
    unless people.nil?
        people.update(end_date:  date_end,  updated_at: Time.now)
    else
      if rada_id == 5030
        People.create(
            first_name: name_array[1],
            middle_name: name_array[2],
            last_name: name_array[0],
            full_name: name_array.join(' '),
            deputy_id: rada_id,
            okrug: nil,
            photo_url: image,
            faction: party,
            end_date:  date_end,
            start_date:  "2017-01-13",
            created_at: Time.now,
            updated_at: Time.now
        )
      else
        People.create(
            first_name: name_array[1],
            middle_name: name_array[2],
            last_name: name_array[0],
            full_name: name_array.join(' '),
            deputy_id: rada_id,
            okrug: nil,
            photo_url: image,
            faction: party,
            end_date:  date_end,
            created_at: Time.now,
            updated_at: Time.now
        )
      end
    end
  end
end



