import neovim
import datetime
import string

authorTpl = string.Template('@Author: $author')
emailTpl = string.Template('@Email: $email')
dateTpl = string.Template('@Date: $date')
modifiedByTpl = string.Template('@Last Modified by: $modifiedBy')
modifiedTimeTpl = string.Template('@Last Modified time: $modifiedTime')

@neovim.plugin
class FileHeaderPlugin(object):
    def __init__(self, nvim):
        self.nvim = nvim

    def message(self, message):
        self.nvim.command('echo "' + message + '"')

    def getCurrentTime(self):
        now = datetime.datetime.now()
        return now.strftime("%Y-%m-%d %H:%M:%S")

    def getGitConfig(self, key):
        out = self.nvim.funcs.system('git config user.' + key)
        value = out.split("\n")[0]
        return value

    def getDelimiter(self):
        filetype = self.nvim.current.buffer.options['filetype']
        delimiterMap = self.nvim.eval('g:fileheader_delimiter_map')
        return delimiterMap[filetype]

    def getFields(self):
        fields = {}

        fieldsByGit = self.nvim.eval('g:fileheader_by_git_config')
        username = self.getGitConfig('name')
        if fieldsByGit and username:
            fields['author'] = username
            fields['email'] = self.getGitConfig('email')
        else:
            fields['author'] = self.nvim.eval('g:fileheader_default_author')
            fields['email'] = self.nvim.eval('g:fileheader_default_email')
        return fields

    def generateHeader(self, delimiter, fields):
        begin = delimiter['begin']
        char = delimiter['char']
        end = delimiter['end']

        currentTime = self.getCurrentTime()
        author = char + authorTpl.substitute(author = fields['author'])
        date = char + dateTpl.substitute(date = currentTime)
        modifiedBy = char + modifiedByTpl.substitute(modifiedBy = fields['author'])
        modifiedTime = char + modifiedTimeTpl.substitute(modifiedTime = currentTime)

        showEmail = self.nvim.eval('g:fileheader_show_email')
        if showEmail and len(fields['email']):
            email = char + emailTpl.substitute(email = fields['email'])
            return [begin, author, email, date, modifiedBy, modifiedTime, end]
        else:
            return [begin, author, date, modifiedBy, modifiedTime, end]

    @neovim.command('AddFileHeader', range='', nargs='*', sync=True)
    def addFileHeader(self, args, range):
        delimiter = self.getDelimiter()
        fields = self.getFields()

        if len(fields['author']):
            header = self.generateHeader(delimiter, fields)
            newLineAtEnd = self.nvim.eval('g:fileheader_new_line_at_end')
            if newLineAtEnd:
                header.append('')
            self.nvim.current.buffer.append(header, 0)
        else:
            self.message('fileheader.nvim: please set the your author field')

