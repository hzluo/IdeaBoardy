require 'test_helper'

class BoardsControllerTest < ActionController::TestCase
  setup do
    @board1 = boards(:one)
    @board2 = boards(:two)
    @section1 = sections(:one)
    @section2 = sections(:two)
  end

  test "should get index" do
    expected_boards = [@board1, @board2]
    get :index
    assert_response :success
    actual_boards = ActiveSupport::JSON.decode @response.body
    assert_equal expected_boards.count, actual_boards.count
    expected_boards.each_with_index do |expected_board, index|
      assert_equal expected_board.id, actual_boards[index]['id']
      assert_equal expected_board.name, actual_boards[index]['name']
      links = actual_boards[index]['links']
      assert_equal 1, links.count
      board_link = links.select { |l| l['rel'] == 'board' }.first
      assert_equal board_url(expected_board.id), board_link['href']
    end
  end

  test "should create board" do
    expected_name = "New board name"
    expected_description = "New board description"
    assert_difference('Board.count') do
      post :create, board: {name: expected_name, description: expected_description}
    end
    created_board = assigns :board
    assert_response :created
    assert_equal board_url(created_board.id), @response.headers['Location']
    assert_blank @response.body
    actual_board = Board.find created_board.id
    assert_equal expected_name, actual_board.name
    assert_equal expected_description, actual_board.description
  end

  test "should return unprocessable_entity status when create a board without name" do
    post :create, board: {}
    assert_response :unprocessable_entity
    errors = ActiveSupport::JSON.decode @response.body
    assert_includes errors["name"], "can't be blank"
  end

  test "should show board" do
    get :show, id: @board1.id
    assert_response :success
    actual_board = ActiveSupport::JSON.decode @response.body
    assert_equal @board1.id, actual_board['id']
    assert_equal @board1.name, actual_board['name']
    assert_equal @board1.description, actual_board['description']
    links = actual_board['links']
    assert_equal 2, links.count
    self_link = links.select { |l| l['rel']=='self' }.first
    assert_equal board_url(@board1.id), self_link['href']
    sections_link = links.select { |l| l['rel']=='sections' }.first
    assert_equal board_sections_url(@board1.id), sections_link['href']
  end

  test "should return 404 Not Found when board is not existed (GET)" do
    get :show, id: 99999
    assert_response :not_found
    assert_blank @response.body
  end

  test "should update board" do
    expected_name = "New board name"
    expected_description = "New board description"
    put :update, id: @board1.id, board: {description: expected_description, name: expected_name}
    assert_response :no_content
    assert_blank @response.body
    actual_board = Board.find @board1.id
    assert_equal expected_name, actual_board.name
    assert_equal expected_description, actual_board.description
  end

  test "should return unprocessable_entity status when clear name of a board" do
    put :update, id: @board1.id, board: {name: ""}
    assert_response :unprocessable_entity
    errors = ActiveSupport::JSON.decode @response.body
    assert_includes errors["name"], "can't be blank"
  end

  test "should return 404 Not Found when board is not existed (UPDATE)" do
    put :update, id: 99999, board: {description: "new board description", name: "new board name"}
    assert_response :not_found
    assert_blank @response.body
  end

  test "should destroy board, associated sections and ideas" do
    section_ids = @board1.sections.collect { |s| s.id }
    idea_ids = @board1.sections.collect { |s| s.ideas }.flatten.collect { |i| i.id }
    assert_difference('Board.count', -1) do
      delete :destroy, id: @board1.id
    end
    assert_response :no_content
    assert_blank @response.body
    assert_equal false, Board.exists?(@board1.id), "Board should be deleted."
    section_ids.each { |id| assert_equal false, Section.exists?(id), "Associated sections should be deleted." }
    idea_ids.each { |id| assert_equal false, Idea.exists?(id), "Associated ideas should be deleted." }
  end

  test "should return 204 No Content when board is not existed" do
    delete :destroy, id: 99999
    assert_response :no_content
    assert_blank @response.body
  end

  test "should get report of first board" do
    expected_board = Board.find(@board1.id)
    get :report, id: @board1.id
    assert_response :success
    actual_report = ActiveSupport::JSON.decode @response.body
    assert_equal expected_board.name, actual_report['name']
    assert_equal expected_board.description, actual_report['description']
    assert_equal expected_board.sections.count, actual_report['sections'].count
    expected_board.sections.order('id').each_with_index do |section, section_index|
      actual_section_report = actual_report['sections'][section_index]
      assert_equal section.name, actual_section_report['name']
      section.ideas.order('vote desc').each_with_index do |idea, idea_index|
        actual_idea_report = actual_section_report['ideas'][idea_index]
        assert_equal idea.content, actual_idea_report['content']
        assert_equal idea.vote, actual_idea_report['vote']
      end
    end
    links = actual_report['links']
    assert_equal 2, links.count
    self_link = links.select { |l| l['rel']=='self' }.first
    assert_equal "#{board_url(@board1.id)}/report", self_link['href']
    board_link = links.select { |l| l['rel']=='board' }.first
    assert_equal board_url(@board1.id), board_link['href']
  end

  test "should return 404 Not Found when board is not existed (report)" do
    get :report, id: 99999
    assert_response :not_found
    assert_blank @response.body
  end
end
