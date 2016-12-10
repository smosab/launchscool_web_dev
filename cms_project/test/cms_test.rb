ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "pry"

require_relative "../cms"

require "fileutils"

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end


class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index

    create_document "about.txt"
    create_document "changes.txt"
    create_document "history.txt"
    # create_document "ruby.md"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
    # assert_includes last_response.body, "ruby.md"
  end

  def test_history
    create_document "history.txt", "R1993 - Yukihiro Matsumoto dreams up Ruby."

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
    create_document "ruby.md", "#Ruby is..."

    get "/ruby.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_edit_file_page
    create_document "about.txt"

    get "/edit/about.txt"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_update_file
    create_document "changes.txt"

    post "/update/changes.txt", updated_text: "new content"

    assert_equal 302, last_response.status
    # binding.pry

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_create_doc
    get "/create/doc"

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<form action="/add/doc"'
  end

  def test_add_file
    post "/add/doc", docname: "anewdoc.txt"

    assert_equal 302, last_response.status

    get last_response["Location"]


    assert_includes last_response.body, "anewdoc.txt has been created."

    assert_includes last_response.body, "<a href = \"/anewdoc.txt\">"

  end

  def test_create_new_document_without_filename
      post "/add/doc", docname: ""

      assert_equal 422, last_response.status

      assert_includes last_response.body, "A name is required"
  end

end

