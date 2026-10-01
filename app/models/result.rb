require "ostruct"

class Result
  attr_reader :data, :error

  def self.success(data = nil)
    new(data: data)
  end

  def self.failure(error)
    new(error: error)
  end

  def self.try
    success(yield)
  rescue StandardError => exception
    failure(
      OpenStruct.new(
        message: exception.message,
        exception_class: exception.class.name,
        backtrace: exception.backtrace
      )
    )
  end

  def initialize(data: nil, error: nil)
    @data = data
    @error = error
  end

  def success?
    @error.blank?
  end

  def failure?
    !success?
  end
end
