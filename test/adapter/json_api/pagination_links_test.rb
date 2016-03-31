require 'test_helper'
require 'will_paginate/array'
require 'kaminari'
require 'kaminari/hooks'
::Kaminari::Hooks.init

module ActiveModelSerializers
  module Adapter
    class JsonApi
      class PaginationLinksTest < ActiveSupport::TestCase
        URI = 'http://example.com'.freeze

        def setup
          ActionController::Base.cache_store.clear
          @array = [
            Profile.new({ id: 1, name: 'Name 1', description: 'Description 1', comments: 'Comments 1' }),
            Profile.new({ id: 2, name: 'Name 2', description: 'Description 2', comments: 'Comments 2' }),
            Profile.new({ id: 3, name: 'Name 3', description: 'Description 3', comments: 'Comments 3' }),
            Profile.new({ id: 4, name: 'Name 4', description: 'Description 4', comments: 'Comments 4' }),
            Profile.new({ id: 5, name: 'Name 5', description: 'Description 5', comments: 'Comments 5' })
          ]
        end

        def mock_request(query_parameters = {}, original_url = URI)
          context = Minitest::Mock.new
          context.expect(:request_url, original_url)
          context.expect(:query_parameters, query_parameters)
          context.expect(:key_transform, nil)
          @options = {}
          @options[:serialization_context] = context
        end

        def load_adapter(paginated_collection, options = {})
          options = options.merge(adapter: :json_api)
          ActiveModelSerializers::SerializableResource.new(paginated_collection, options)
        end

        def using_kaminari(page = 2)
          Kaminari.paginate_array(@array).page(page).per(2)
        end

        def using_will_paginate(page = 2)
          @array.paginate(page: page, per_page: 2)
        end

        def data
          { data: [
              { id: '1', type: 'profiles', attributes: { name: 'Name 1', description: 'Description 1' } },
              { id: '2', type: 'profiles', attributes: { name: 'Name 2', description: 'Description 2' } },
              { id: '3', type: 'profiles', attributes: { name: 'Name 3', description: 'Description 3' } },
              { id: '4', type: 'profiles', attributes: { name: 'Name 4', description: 'Description 4' } },
              { id: '5', type: 'profiles', attributes: { name: 'Name 5', description: 'Description 5' } }
            ]
          }
        end

        def links
          {
            links: {
              self: "#{URI}?page%5Bnumber%5D=2&page%5Bsize%5D=2",
              first: "#{URI}?page%5Bnumber%5D=1&page%5Bsize%5D=2",
              prev: "#{URI}?page%5Bnumber%5D=1&page%5Bsize%5D=2",
              next: "#{URI}?page%5Bnumber%5D=3&page%5Bsize%5D=2",
              last: "#{URI}?page%5Bnumber%5D=3&page%5Bsize%5D=2"
            }
          }
        end

        def last_page_links
          {
            links: {
              self: "#{URI}?page%5Bnumber%5D=3&page%5Bsize%5D=2",
              first: "#{URI}?page%5Bnumber%5D=1&page%5Bsize%5D=2",
              prev: "#{URI}?page%5Bnumber%5D=2&page%5Bsize%5D=2"
            }
          }
        end

        def expected_response_without_pagination_links
          data
        end

        def expected_response_with_pagination_links
          {}.tap do |hash|
            hash[:data] = data.values.flatten[2..3]
            hash.merge! links
          end
        end

        def expected_response_with_pagination_links_and_additional_params
          new_links = links[:links].each_with_object({}) { |(key, value), hash| hash[key] = "#{value}&test=test" }
          {}.tap do |hash|
            hash[:data] = data.values.flatten[2..3]
            hash.merge! links: new_links
          end
        end

        def expected_response_with_last_page_pagination_links
          {}.tap do |hash|
            hash[:data] = [data.values.flatten.last]
            hash.merge! last_page_links
          end
        end

        def test_pagination_links_using_kaminari
          adapter = load_adapter(using_kaminari)

          mock_request
          assert_equal expected_response_with_pagination_links, adapter.serializable_hash(@options)
        end

        def test_pagination_links_using_will_paginate
          adapter = load_adapter(using_will_paginate)

          mock_request
          assert_equal expected_response_with_pagination_links, adapter.serializable_hash(@options)
        end

        def test_pagination_links_with_additional_params
          adapter = load_adapter(using_will_paginate)

          mock_request({ test: 'test' })
          assert_equal expected_response_with_pagination_links_and_additional_params,
            adapter.serializable_hash(@options)
        end

        def test_last_page_pagination_links_using_kaminari
          adapter = load_adapter(using_kaminari(3))

          mock_request
          assert_equal expected_response_with_last_page_pagination_links, adapter.serializable_hash(@options)
        end

        def test_last_page_pagination_links_using_will_paginate
          adapter = load_adapter(using_will_paginate(3))

          mock_request
          assert_equal expected_response_with_last_page_pagination_links, adapter.serializable_hash(@options)
        end

        def test_not_showing_pagination_links
          adapter = load_adapter(@array)

          assert_equal expected_response_without_pagination_links, adapter.serializable_hash
        end
      end
    end
  end
end