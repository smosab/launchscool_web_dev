ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "pry"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

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

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    {"rack.session" => { username: "admin", signedin: "true" } }
  end

  def test_index
    post "/users/validate", username: "admin", password: "secret"

    create_document "about.txt"
    create_document "changes.txt"
    create_document "history.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
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

    assert_equal "notafile.ext doesn't exist", session[:error]
  end

  def test_markdown
    create_document "ruby.md", "#Ruby is..."

    get "/ruby.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_edit_file_page

    create_document "about.txt"

    get "/edit/about.txt", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_update_file
    create_document "changes.txt"

    post "/update/changes.txt", updated_text: "new content"

    assert_equal 302, last_response.status

    assert_equal "changes.txt has been updated.", session[:update_msg]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_create_doc
    get "/create/doc", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<form action="/add/doc"'
  end

  def test_add_file
    post "/users/validate", username: "admin", password: "secret"

    post "/add/doc", docname: "anewdoc.txt"

    assert_equal 302, last_response.status

    assert_equal "anewdoc.txt has been created.", session[:update_msg]

    get last_response["Location"]
    assert_includes last_response.body, "<a href = \"/anewdoc.txt\">"

  end

  def test_create_new_document_without_filename
      post "/add/doc", docname: ""

      assert_equal 422, last_response.status

      assert_includes last_response.body, "A name is required"
  end

  def test_delete_file
    create_document "test1.txt"

    post "/delete/test1.txt", {}, admin_session

    assert_equal 302, last_response.status

    assert_equal "test1.txt was deleted.", session[:update_msg]

  end

    def test_signin_form
    get "/users/signin"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_signin
    post "/users/validate", username: "admin", password: "secret"
    assert_equal 302, last_response.status

    assert_equal "Welcome!", session[:update_msg]
    assert_equal "admin", session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/validate", username: "guest", password: "shhhh"
    assert_equal 302, last_response.status
    assert_equal nil, session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Invalid Credentials"
  end


def test_signout
    # post "/users/validate", username: "admin", password: "secret"
    # get last_response["Location"]
    # assert_includes last_response.body, "Welcome!"

    get "/", {}, {"rack.session" => { username: "admin", signedin: "true" } }

    assert_includes last_response.body, "Signed in as admin"

    get "/users/signout"
    get last_response["Location"]

    assert_includes last_response.body, "You have been signed out."
    assert_includes last_response.body, "Sign In"
  end

  # def test_editing_document
  #   get "/changes.txt/edit", {}, admin_session

  #   assert_equal 200, last_response.status
  # end

end

