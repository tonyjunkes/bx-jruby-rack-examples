class Comment < ApplicationRecord
    belongs_to :ticket
    belongs_to :agent
    validates :body, presence: true, length: { maximum: 5000 }
end
