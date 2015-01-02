require File.expand_path("../helper", __FILE__)

module Hurley
  class UrlTest < TestCase
    def test_integration_join
      test = Test.new

      ["/foo/bar", "/foo", "/baz"].each do |path|
        test.get("http://example.com" + path) do |req|
          [200, {}, "#{path} http #{req.url.raw_query}".strip]
        end

        test.get("https://sub.example.com" + path) do |req|
          [200, {}, "#{path} sub #{req.url.raw_query}".strip]
        end

        test.get(path + "?v=1") do |req|
          [200, {}, "#{path} v1 #{req.url.raw_query}".strip]
        end

        test.get(path + "?v=2") do |req|
          [200, {}, "#{path} v2 #{req.url.raw_query}".strip]
        end

        test.get(path) do |req|
          [200, {}, "#{path} #{req.url.raw_query}".strip]
        end

        test.get("https://example.com" + path) do |req|
          [500, {}, "unreachable"]
        end
      end

      errors = []

      extra_tests = {
        "http://example.com/foo" => "/foo http",
        "http://example.com/foo/bar" => "/foo/bar http",
        "http://example.com/baz" => "/baz http",

        "https://sub.example.com/foo" => "/foo sub",
        "https://sub.example.com/foo/bar" => "/foo/bar sub",
        "https://sub.example.com/baz" => "/baz sub",
      }

      root_tests = extra_tests.merge(
        "/foo" => "/foo",
        "/foo/" => "/foo",
        "/foo/bar" => "/foo/bar",
        "/foo/bar/" => "/foo/bar",
        "/baz" => "/baz",
        "/baz/" => "/baz",
        "foo" => "/foo",
        "foo/" => "/foo",
        "foo/bar" => "/foo/bar",
        "foo/bar/" => "/foo/bar",
        "baz" => "/baz",
        "baz/" => "/baz",

        # v1
        "/foo?v=1" => "/foo v1 v=1",
        "/foo/?v=1" => "/foo v1 v=1",
        "/foo/bar?v=1" => "/foo/bar v1 v=1",
        "/foo/bar/?v=1" => "/foo/bar v1 v=1",
        "/baz?v=1" => "/baz v1 v=1",
        "/baz/?v=1" => "/baz v1 v=1",
        "foo?v=1" => "/foo v1 v=1",
        "foo/?v=1" => "/foo v1 v=1",
        "foo/bar?v=1" => "/foo/bar v1 v=1",
        "foo/bar/?v=1" => "/foo/bar v1 v=1",
        "baz?v=1" => "/baz v1 v=1",
        "baz/?v=1" => "/baz v1 v=1",

        # v2
        "/foo?v=2" => "/foo v2 v=2",
        "/foo/?v=2" => "/foo v2 v=2",
        "/foo/bar?v=2" => "/foo/bar v2 v=2",
        "/foo/bar/?v=2" => "/foo/bar v2 v=2",
        "/baz?v=2" => "/baz v2 v=2",
        "/baz/?v=2" => "/baz v2 v=2",
        "foo?v=2" => "/foo v2 v=2",
        "foo/?v=2" => "/foo v2 v=2",
        "foo/bar?v=2" => "/foo/bar v2 v=2",
        "foo/bar/?v=2" => "/foo/bar v2 v=2",
        "baz?v=2" => "/baz v2 v=2",
        "baz/?v=2" => "/baz v2 v=2",
      )

      foo_tests = extra_tests.merge(
        "" => "/foo",
        "bar" => "/foo/bar",
        "bar/" => "/foo/bar",
        "/foo" => "/foo",
        "/foo/" => "/foo",
        "/foo/bar" => "/foo/bar",
        "/foo/bar/" => "/foo/bar",
        "/baz" => "/baz",
        "/baz/" => "/baz",
      )

      {
        "https://example.com" => root_tests,
        "https://example.com/" => root_tests,
        "https://example.com/foo" => foo_tests,
        "https://example.com/foo/" => foo_tests,
      }.each do |endpoint, requests|
        cli = Client.new(endpoint)
        cli.connection = test

        requests.each do |path, expected|
          res = cli.get(path)
          if res.body != expected
            errors << "#{endpoint} + #{path} == #{res.request.url.inspect}"
            errors << "  #{expected.inspect} != #{res.body.inspect}"
          end
        end
      end

      if errors.any?
        fail "\n" + errors.join("\n")
      end
    end

    def test_join
      errors = []

      {
        "https://example.com?v=1" => {
          ""             => "https://example.com?v=1",
          "/"            => "https://example.com/?v=1",
          "?a=1"         => "https://example.com?a=1&v=1",
          "/?a=1"        => "https://example.com/?a=1&v=1",
          "?v=2&a=1"     => "https://example.com?v=2&a=1",
          "/?v=2&a=1"    => "https://example.com/?v=2&a=1",
          "a"            => "https://example.com/a?v=1",
          "a/"           => "https://example.com/a/?v=1",
          "a?a=1"        => "https://example.com/a?a=1&v=1",
          "a/?a=1"       => "https://example.com/a/?a=1&v=1",
          "a?v=2&a=1"    => "https://example.com/a?v=2&a=1",
          "a/?v=2&a=1"   => "https://example.com/a/?v=2&a=1",
          "a/b"          => "https://example.com/a/b?v=1",
          "a/b/"         => "https://example.com/a/b/?v=1",
          "a/b?a=1"      => "https://example.com/a/b?a=1&v=1",
          "a/b/?a=1"     => "https://example.com/a/b/?a=1&v=1",
          "a/b?v=2&a=1"  => "https://example.com/a/b?v=2&a=1",
          "a/b/?v=2&a=1" => "https://example.com/a/b/?v=2&a=1",
        },

        "https://example.com/?v=1" => {
          ""             => "https://example.com/?v=1",
          "/"            => "https://example.com/?v=1",
          "?a=1"         => "https://example.com/?a=1&v=1",
          "/?a=1"        => "https://example.com/?a=1&v=1",
          "?v=2&a=1"     => "https://example.com/?v=2&a=1",
          "/?v=2&a=1"    => "https://example.com/?v=2&a=1",
          "a"            => "https://example.com/a?v=1",
          "a/"           => "https://example.com/a/?v=1",
          "a?a=1"        => "https://example.com/a?a=1&v=1",
          "a/?a=1"       => "https://example.com/a/?a=1&v=1",
          "a?v=2&a=1"    => "https://example.com/a?v=2&a=1",
          "a/?v=2&a=1"   => "https://example.com/a/?v=2&a=1",
          "a/b"          => "https://example.com/a/b?v=1",
          "a/b/"         => "https://example.com/a/b/?v=1",
          "a/b?a=1"      => "https://example.com/a/b?a=1&v=1",
          "a/b/?a=1"     => "https://example.com/a/b/?a=1&v=1",
          "a/b?v=2&a=1"  => "https://example.com/a/b?v=2&a=1",
          "a/b/?v=2&a=1" => "https://example.com/a/b/?v=2&a=1",
        },

        "https://example.com/a?v=1" => {
          ""              => "https://example.com/a?v=1",
          "/"             => "https://example.com/?v=1",
          "?a=1"          => "https://example.com/a?a=1&v=1",
          "/?a=1"         => "https://example.com/?a=1&v=1",
          "?v=2&a=1"      => "https://example.com/a?v=2&a=1",
          "/?v=2&a=1"     => "https://example.com/?v=2&a=1",
          "/a"            => "https://example.com/a?v=1",
          "/a/"           => "https://example.com/a/?v=1",
          "/a?a=1"        => "https://example.com/a?a=1&v=1",
          "/a/?a=1"       => "https://example.com/a/?a=1&v=1",
          "/a?v=2&a=1"    => "https://example.com/a?v=2&a=1",
          "/a/?v=2&a=1"   => "https://example.com/a/?v=2&a=1",
          "/a/b"          => "https://example.com/a/b?v=1",
          "/a/b/"         => "https://example.com/a/b/?v=1",
          "/a/b?a=1"      => "https://example.com/a/b?a=1&v=1",
          "/a/b/?a=1"     => "https://example.com/a/b/?a=1&v=1",
          "/a/b?v=2&a=1"  => "https://example.com/a/b?v=2&a=1",
          "/a/b/?v=2&a=1" => "https://example.com/a/b/?v=2&a=1",
          "c"             => "https://example.com/a/c?v=1",
          "c/"            => "https://example.com/a/c/?v=1",
          "c?a=1"         => "https://example.com/a/c?a=1&v=1",
          "c/?a=1"        => "https://example.com/a/c/?a=1&v=1",
          "c?v=2&a=1"     => "https://example.com/a/c?v=2&a=1",
          "c/?v=2&a=1"    => "https://example.com/a/c/?v=2&a=1",
          "/c"            => "https://example.com/c?v=1",
          "/c/"           => "https://example.com/c/?v=1",
          "/c?a=1"        => "https://example.com/c?a=1&v=1",
          "/c/?a=1"       => "https://example.com/c/?a=1&v=1",
          "/c?v=2&a=1"    => "https://example.com/c?v=2&a=1",
          "/c/?v=2&a=1"   => "https://example.com/c/?v=2&a=1",
        },

        "https://example.com/a/?v=1" => {
          ""              => "https://example.com/a/?v=1",
          "/"             => "https://example.com/?v=1",
          "?a=1"          => "https://example.com/a/?a=1&v=1",
          "/?a=1"         => "https://example.com/?a=1&v=1",
          "?v=2&a=1"      => "https://example.com/a/?v=2&a=1",
          "/?v=2&a=1"     => "https://example.com/?v=2&a=1",
          "/a"            => "https://example.com/a?v=1",
          "/a/"           => "https://example.com/a/?v=1",
          "/a?a=1"        => "https://example.com/a?a=1&v=1",
          "/a/?a=1"       => "https://example.com/a/?a=1&v=1",
          "/a?v=2&a=1"    => "https://example.com/a?v=2&a=1",
          "/a/?v=2&a=1"   => "https://example.com/a/?v=2&a=1",
          "/a/b"          => "https://example.com/a/b?v=1",
          "/a/b/"         => "https://example.com/a/b/?v=1",
          "/a/b?a=1"      => "https://example.com/a/b?a=1&v=1",
          "/a/b/?a=1"     => "https://example.com/a/b/?a=1&v=1",
          "/a/b?v=2&a=1"  => "https://example.com/a/b?v=2&a=1",
          "/a/b/?v=2&a=1" => "https://example.com/a/b/?v=2&a=1",
          "c"             => "https://example.com/a/c?v=1",
          "c/"            => "https://example.com/a/c/?v=1",
          "c?a=1"         => "https://example.com/a/c?a=1&v=1",
          "c/?a=1"        => "https://example.com/a/c/?a=1&v=1",
          "c?v=2&a=1"     => "https://example.com/a/c?v=2&a=1",
          "c/?v=2&a=1"    => "https://example.com/a/c/?v=2&a=1",
          "/c"            => "https://example.com/c?v=1",
          "/c/"           => "https://example.com/c/?v=1",
          "/c?a=1"        => "https://example.com/c?a=1&v=1",
          "/c/?a=1"       => "https://example.com/c/?a=1&v=1",
          "/c?v=2&a=1"    => "https://example.com/c?v=2&a=1",
          "/c/?v=2&a=1"   => "https://example.com/c/?v=2&a=1",
        },
      }.each do |endpoint, tests|
        absolute = Url.parse(endpoint)
        tests.each do |input, expected|
          actual = Url.join(absolute, input).to_s
          if actual != expected
            errors << "#{endpoint.inspect} + #{input.inspect} = #{actual.inspect}"
          end
        end
      end

      if errors.any?
        fail "\n" + errors.join("\n")
      end
    end

    def test_escape
      {
        "abc"  => "abc",
        "a/b"  => "a%2Fb",
        "a b"  => "a%20b",
        "a+b"  => "a%2Bb",
        "a +b" => "a%20%2Bb",
        "a&b"  => "a%26b",
        "a=b"  => "a%3Db",
        "a;b"  => "a%3Bb",
        "a?b"  => "a%3Fb",
      }.each do |input, expected|
        assert_equal expected, Url.escape_path(input)
      end
    end

    def test_escape_paths
      assert_equal "a%20%2B%201/b%3B1", Url.escape_paths("a + 1", "b;1")
    end

    def test_parse_empty
      u = Url.parse(nil)
      assert_nil u.scheme
      assert_nil u.host
      assert_nil u.port
      assert_equal "", u.path
      assert_equal "", u.to_s
    end

    def test_parse_only_path
      u = Url.parse("/foo")
      assert_nil u.scheme
      assert_nil u.host
      assert_nil u.port
      assert_equal "/foo", u.path
      assert_equal "/foo", u.to_s
    end

    def test_parse_url_with_host
      u = Url.parse("https://example.com?a=1")
      assert_equal "https", u.scheme
      assert_equal "example.com", u.host
      assert_equal 443, u.port
      assert_equal "", u.path
      assert_equal "a=1", u.raw_query
      assert_equal %w(a), u.query.keys
      assert_equal "1", u.query["a"]
      assert_equal "https://example.com?a=1", u.to_s
    end

    def test_parse_url_with_slash
      u = Url.parse("https://example.com/?a=1")
      assert_equal "https", u.scheme
      assert_equal "example.com", u.host
      assert_equal 443, u.port
      assert_equal "/", u.path
      assert_equal "a=1", u.raw_query
      assert_equal %w(a), u.query.keys
      assert_equal "1", u.query["a"]
      assert_equal "https://example.com/?a=1", u.to_s
    end

    def test_parse_url_with_path
      u = Url.parse("https://example.com/foo?a=1")
      assert_equal "https", u.scheme
      assert_equal "example.com", u.host
      assert_equal 443, u.port
      assert_equal "/foo", u.path
      assert_equal "a=1", u.raw_query
      assert_equal %w(a), u.query.keys
      assert_equal "1", u.query["a"]
      assert_equal "https://example.com/foo?a=1", u.to_s
    end
  end
end
