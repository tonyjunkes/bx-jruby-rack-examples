class Customer < ApplicationRecord
    has_many :tickets
    validates :name, :company, :email, presence: true, length: { maximum: 200 }
    validates :email, format: { with: /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/ }
end
