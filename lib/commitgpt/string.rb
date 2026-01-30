# frozen_string_literal: true

require 'tty-prompt'

# Monkey patch TTY::Prompt::List to add padding at the bottom of menus
module TTY
  class Prompt
    # Monkey patch to add padding
    class List
      alias original_render_menu render_menu

      # Override render_menu to add empty lines at the bottom
      def render_menu
        output = original_render_menu
        # Add 2 empty lines at the bottom so menu doesn't stick to terminal edge
        "#{output}\n\n"
      end
    end
  end
end

# Open String to add color
class String
  def red
    "\e[31m#{self}\e[0m"
  end

  def green
    "\e[32m#{self}\e[0m"
  end

  def gray
    "\e[90m#{self}\e[0m"
  end

  def magenta
    "\e[35m#{self}\e[0m"
  end

  def cyan
    "\e[36m#{self}\e[0m"
  end

  def yellow
    "\e[33m#{self}\e[0m"
  end
end
