require 'benchmark'

class BaseType < GraphQL::Schema::Object
  field_class GraphQL::Cache::Field
end

class OrderType < BaseType
  field :id, Int, null: false
  field :number, Int, null: true
  field :total_price_cents, Int, null: true, extensions: [::GraphQL::Cache::FieldExtension]
end

class CustomerType < BaseType
  field :display_name, String, null: false
  field :email, String, null: false
  field :orders, OrderType.connection_type, null: false, extensions: [
    ::GraphQL::Cache::FieldExtension
  ]
end

class QueryType < BaseType
  field :customer, CustomerType, null: true, extensions: [::GraphQL::Cache::FieldExtension] do
    argument :id, ID, 'Unique Identifier for querying a specific user', required: true
  end

  def customer(id:)
    Customer[id]
  end
end

class CacheSchema < GraphQL::Schema
  query QueryType

  use GraphQL::Execution::Interpreter
  use GraphQL::Cache

  default_max_page_size 50

  def self.resolve_type(_type, obj, _ctx)
    "#{obj.class.name}Type"
  end

  def self.texecute(*args, **kwargs)
    result = nil
    measurement = Benchmark.measure { result = execute(*args, *kwargs) }
    GraphQL::Cache.logger.debug("Query executed in #{measurement.real}")
    result
  end
end
