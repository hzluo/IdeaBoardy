require 'test_helper'

class SectionTest < ActiveSupport::TestCase
  setup do
    Section.delete_all
    Board.delete_all
  end

  test "should add an idea" do
    section = Section.new name: "Section name"
    section.save

    idea = Idea.new content: "Idea content"
    section.ideas << idea

    actual_section = Section.find section.id
    assert_equal 1, actual_section.ideas.count
    assert_equal idea.id, actual_section.ideas.first.id
  end

  test "section name should be unique under the same board" do
    board = Board.create(name: "Board name")
    section_name = "Section name"
    section = Section.new(name: section_name)
    section.board = board
    section.save!

    assert_raise "Section with duplicated name should not be created.", ActiveRecord::RecordInvalid do
      section = Section.new(name: section_name)
      section.board = board
      section.save!
    end
  end

  test "section should have name" do
    assert_raise "Section should have name", ActiveRecord::RecordInvalid do
      Section.create!(name: "")
    end
  end

  test "sections with same name are allowed within different boards" do
    board = Board.create!(name: "Board name")
    another_board = Board.create!(name: "Another board name")
    section_name = "Section name"
    existed_section = Section.create!(name: section_name)
    existed_section.board = board
    existed_section.save!
    assert_nothing_raised "sections with same name are allowed within different boards" do
      new_section = Section.create!(name: section_name)
      new_section.board = another_board
      new_section.save!
    end
  end
end
