# Code adapted from https://github.com/jashank/punchcard-plot

module Birdwatcher
  class Punchcard
    LEFT_PADDING = 10
    TOP_PADDING  = 10

    WIDTH = 1100

    DAYS  = %w(Sat Fri Thu Wed Tue Mon Sun)
    HOURS = %w(12am 1 2 3 4 5 6 7 8 9 10 11 12pm 1 2 3 4 5 6 7 8 9 10 11)

    FONT_FACE = "sans-serif"

    def initialize(timestamps)
      @timestamps = timestamps
    end

    def generate(destination)
      @data_log  = Hash.new { |h, k| h[k] = Hash.new }
      final_data = []
      @timestamps.each do |timestamp|
        day  = timestamp.strftime("%a")
        hour = timestamp.strftime("%H").to_i
        @data_log[day][hour] = (@data_log[day][hour] || 0) + 1
      end
      @data_log.each do |d, hour_pair|
        hour_pair.each do |h, value|
          glr = @data_log[d][h] * 1.0
          glr /= max_value
          glr *= max_range
          glrb = get_weight(glr)
          final_data.push([glrb, get_x_y_from_day_and_hour(d, h)])
        end
      end
      final_data.each do |x|
        draw_circle(x[1], x[0])
      end
      surface.write_to_png(destination)
    end

    private

    def width
      WIDTH
    end

    def height
      (width / 2.75).round(0)
    end

    def distance
      distance = Math.sqrt((width * height) / 270.5).round
      if distance % 2 == 1
        distance -= 1
      end
      distance
    end

    def max_range
      (distance / 2)**2
    end

    def left
      (width / 18) + LEFT_PADDING
    end

    def indicator_length
      height / 20
    end

    def top
      indicator_length + TOP_PADDING
    end

    def get_x_y_from_day_and_hour(day, hour)
      y = top + (DAYS.index(day.to_s) + 1) * distance
      x = left + (hour.to_i + 1) * distance
      [x, y]
    end

    def get_weight(number)
      return 0 if number.zero?
      (1..(distance / 2)).to_a.each do |i|
        if i * i <= number && number < (i + 1) * (i + 1)
          return i
        end
      end

      if number == max_range
        return distance/2-1
      end

      nil
    end

    def all_values
      @all_values = []
      @data_log.each do |d, e|
        e.each do |h, i|
          @all_values << @data_log[d][h]
        end
      end
      @all_values
    end

    def max_value
      all_values.sort.last
    end

    def surface
      @surface ||= Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, width, height)
    end

    def context
      @context ||= Cairo::Context.new(surface).tap do |c|
        c.line_width = 1
        c.set_source_rgb(1, 1, 1)
        c.rectangle(0, 0, width, height)
        c.fill

        # Set black
        c.set_source_rgb(0, 0, 0)

        # Draw X and Y axis
        c.move_to(left, top)
        c.rel_line_to(0, 8 * distance)
        c.rel_line_to(25 * distance, 0)
        c.stroke

        # Draw indicators on X and Y axis
        x, y = left, top
        8.times do
          c.move_to(x, y)
          c.rel_line_to(-indicator_length, 0)
          c.stroke
          y += distance
        end

        x += distance
        26.times do
          c.move_to(x, y)
          c.rel_line_to(0, indicator_length)
          c.stroke
          x += distance
        end

        # Select font
        c.select_font_face(FONT_FACE, Cairo::FONT_SLANT_NORMAL, Cairo::FONT_WEIGHT_NORMAL)

        # Set and appropiate font size
        c.set_font_size(Math.sqrt( (width * height) / 3055.6))

        # Draw days on Y axis
        x, y = (left - 5), (top + distance)
        DAYS.each do |day|
          t_ext = c.text_extents(day.to_s)
          c.move_to(x - indicator_length - t_ext.width, y + t_ext.height / 2)
          c.show_text(day.to_s)
          y += distance
        end

        # Draw hours on X axis
        x, y = (left + distance), (top + (7 + 1) * distance + 5)
        HOURS.each do |hour|
          t_ext = c.text_extents(hour.to_s)
          c.move_to(x - t_ext.width / 2 - t_ext.x_bearing, y + indicator_length + t_ext.height / 2)
          c.show_text(hour.to_s)
          x += distance
        end
      end
    end

    def draw_circle(position, weight)
      x, y  = position
      alpha = (weight.to_f / max_value.to_f)
      context.set_source_rgba(0, 0, 0, alpha)
      context.move_to(x, y)
      context.arc(x, y, weight, 0, 2 * Math::PI)
      context.fill
    end
  end
end
