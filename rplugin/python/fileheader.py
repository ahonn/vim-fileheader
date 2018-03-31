import neovim

@neovim.plugin
class Main(object):
    def __init__(self, vim):
        self.vim = vim

  @neovim.function('AddFileHeaderPython')
  def addFileHeaderPython(self, args):
      self.vim.command('AddFileHeaderPython"')
