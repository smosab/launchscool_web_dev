ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "pry"

require_relative "../cms"


class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
    assert_includes last_response.body, "ruby.md"
  end

  def test_history
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]

    assert_includes last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_document_not_found
    get "/notafile.ext"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status

    assert_includes last_response.body, "notafile.ext doesn't exist"
  end

  def test_md
    get "/ruby.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_edit_file_page
    get "/edit/about.txt"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_update_file

    post "update/changes.txt", updateText: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

end

