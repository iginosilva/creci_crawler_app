class PageControl < ApplicationRecord
  enum status: { pending: 0, complete: 1 }
  has_many :brokers
  has_many :real_estates
end
