class Section < ActiveRecord::Base
  attr_accessible :name
  has_many :ideas
  belongs_to :board
  validates :name, uniqueness: true
end
