module Laser
  module Cutter
    module Notching
      MINIMUM_NOTCHES_PER_SIDE = 3
      # This class represents a single edge of one side: both inside
      # and outside edge of the material.  It's also responsible
      # for calculating the "perfect" notch width.
      class Edge

        attr_accessor :outside, :inside
        attr_accessor :notch_width
        attr_accessor :thickness, :kerf
        attr_accessor :center_out, :corners, :adjust_corners
        attr_accessor :notch_count, :v1, :v2


        def initialize(outside, inside, options = {})
          self.outside = outside.clone
          self.inside = inside.clone

          # two vectors representing directions going from beginning of each inside line to the outside
          self.v1 = [inside.p1.x - outside.p1.x, inside.p1.y - outside.p1.y].map{|e| -(e / e.abs).to_f }
          self.v2 = [inside.p2.x - outside.p2.x, inside.p2.y - outside.p2.y].map{|e| -(e / e.abs).to_f }

          self.v1 = Vector.[](*self.v1)
          self.v2 = Vector.[](*self.v2)

          self.center_out = options[:center_out] || false
          self.thickness = options[:thickness]
          self.corners = options[:corners]
          self.kerf = options[:kerf] || 0
          self.notch_width = options[:notch_width]
          self.adjust_corners = options[:adjust_corners]

          calculate_notch_width!
          adjust_for_kerf!
        end

        def adjust_for_kerf!
          if kerf?
            self.inside  = move_line_for_kerf(inside)
            self.outside = move_line_for_kerf(outside)
          end
        end

        def move_line_for_kerf line
          k = kerf / 2.0
          p1 = line.p1.plus(v1 * k)
          p2 = line.p2.plus(v2 * k)
          Geometry::Line.new(p1, p2).relocate!
        end

        def kerf?
          self.kerf > 0.0
        end

        # face_setting determines if we want that face to have center notch
        # facing out (for a hole, etc).  This works well when we have odd number
        # of notches, but
        def add_across_line?(face_setting)
          notch_count % 4 == 1 ? face_setting : !face_setting
        end

        # True if the first notch should be a tab (sticking out), or false if it's a hole.
        def first_notch_out?
          add_across_line?(center_out)
        end
        private

        def calculate_notch_width!
          count = ((self.inside.length) / notch_width).to_f.ceil + 1
          count = (count / 2 * 2) + 1 # make count always an odd number
          count = [MINIMUM_NOTCHES_PER_SIDE, count].max

          self.notch_width = 1.0 * (self.inside.length) / count
          self.notch_count = count
        end

      end
    end
  end
end
