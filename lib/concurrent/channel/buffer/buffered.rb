require 'concurrent/channel/buffer/base'

module Concurrent
  class Channel
    module Buffer

      # A buffer with a fixed internal capacity. Items can be put onto the
      # buffer without blocking until the internal capacity is reached. Once
      # the buffer is at capacity, subsequent calls to {#put} will block until
      # an item is removed from the buffer, creating spare capacity.
      class Buffered < Base

        # @!macro channel_buffer_initialize
        #
        # @param [Integer] size the maximum capacity of the buffer; must be
        #   greater than zero.
        # @raise [ArgumentError] when the size is zero (0) or less.
        def initialize(size)
          raise ArgumentError.new('size must be greater than 0') if size.to_i <= 0
          super()
          synchronize do
            @size = size.to_i
            @buffer = []
          end
        end

        # @!macro channel_buffer_empty_question
        def empty?
          synchronize { ns_empty? }
        end

        # @!macro channel_buffer_full_question
        #
        # Will return `true` once the number of items in the buffer reaches
        # the {#size} value specified during initialization.
        def full?
          synchronize { ns_full? }
        end

        # @!macro channel_buffer_put
        #
        # New items can be put onto the buffer until the number of items in
        # the buffer reaches the {#size} value specified during
        # initialization.
        def put(item)
          loop do
            synchronize do
              if ns_closed?
                return false
              elsif !ns_full?
                ns_put_onto_buffer(item)
                return true
              end
            end
            Thread.pass
          end
        end

        # @!macro channel_buffer_offer
        #
        # New items can be put onto the buffer until the number of items in
        # the buffer reaches the {#size} value specified during
        # initialization.
        def offer(item)
          synchronize do
            if ns_closed? || ns_full?
              return false
            else
              ns_put_onto_buffer(item)
              return true
            end
          end
        end

        # @!macro channel_buffer_take
        def take
          item, _ = self.next
          item
        end

        # @!macro channel_buffer_next
        def next
          loop do
            synchronize do
              if ns_closed? && ns_empty?
                return NO_VALUE, false
              elsif !ns_empty?
                item = @buffer.shift
                more = !ns_empty? || !ns_closed?
                return item, more
              end
            end
            Thread.pass
          end
        end

        # @!macro channel_buffer_poll
        def poll
          synchronize do
            if ns_empty?
              NO_VALUE
            else
              @buffer.shift
            end
          end
        end

        private

        # @!macro channel_buffer_empty_question
        def ns_empty?
          @buffer.length == 0
        end

        # @!macro channel_buffer_full_question
        def ns_full?
          @buffer.length == @size
        end

        # @!macro channel_buffer_put
        def ns_put_onto_buffer(item)
          @buffer.push(item)
        end
      end
    end
  end
end
