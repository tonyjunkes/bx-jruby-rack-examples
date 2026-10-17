class Agent < ApplicationRecord
    has_many :tickets, foreign_key: :assignee_id
    validates :name, presence: true
end
