# Результаты парсинга.
# В таблице хранятся результаты о различных парсингах (Регионы, объявления и т.д.)
class ParsingResult < ActiveRecord::Base
	belongs_to :region

	enum result_type: [:regions, :adverts]
end
