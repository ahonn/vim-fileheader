# @Author: ahonn
# @Date: 2018-03-31 00:38:28
# @Last Modified by: clouduan
# @Last Modified time: 2018-08-22 16:00:53

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
        self.author = ''
        self.email = ''
        self.date = ''
        self.delimiter = {}
        self.char = ''
        self.begin = ''
        self.end = ''
        self.authorHeader = ''
        self.emailHeader = ''
        self.dateHeader = ''
        self.modifiedByHeader = ''
        self.modifiedTimeHeader = ''

    def message(self, message):
        self.nvim.command('echo "' + message + '"')

    def getCurrentTime(self):
        now = datetime.datetime.now()
        timeStamp = self.nvim.eval('g:fileheader_timestamp_format')
        self.date = now.strftime(timeStamp)
        self.dateHeader = self.char + dateTpl.substitute(date = self.date)

    def getGitConfig(self, key):
        out = self.nvim.funcs.system('git config user.' + key)
        value = out.split("\n")[0]
        return value

    def getDelimiter(self):
        filetype = self.nvim.current.buffer.options['filetype']
        delimiterMap = self.nvim.eval('g:fileheader_delimiter_map')
        if filetype in delimiterMap:
            self.delimiter = delimiterMap[filetype]
            self.begin = self.delimiter['begin']
            self.char = self.delimiter['char']
            self.end = self.delimiter['end']

    def getFields(self):
        fieldsByGit = self.nvim.eval('g:fileheader_by_git_config')
        username = self.getGitConfig('name')
        if fieldsByGit and username:
            self.author = username
            self.email = self.getGitConfig('email')
        else:
            self.author = self.nvim.eval('g:fileheader_default_author')
            self.email = self.nvim.eval('g:fileheader_default_email')

        self.authorHeader = self.char + authorTpl.substitute(author = self.author)

    def showEmail(self):
        if self.nvim.eval('g:fileheader_show_email'):
            self.emailHeader = self.char + emailTpl.substitute(email = self.email)
            return 1
        else:
            return 0

    def showModifiedBy(self):
        if self.nvim.eval('g:fileheader_last_modified_by'):
            self.modifiedByHeader = self.char + modifiedByTpl.substitute(modifiedBy = self.author)
            return 1
        else:
            return 0

    def showModifiedTime(self):
        if self.nvim.eval('g:fileheader_last_modified_time'):
            self.modifiedTimeHeader = self.char + modifiedTimeTpl.substitute(modifiedTime = self.date)
            return 1
        else:
            return 0

    def generateHeader(self):
        """
        return: header = [begin, author, (email), date, (modifiedBy), (modifiedTime), end]
        """
        header = [self.begin, self.authorHeader]

        if self.showEmail() and len(self.email):
            header.append(self.emailHeader)
        header.append(self.dateHeader)

        if self.showModifiedBy():
            header.append(self.modifiedByHeader)
        if self.showModifiedTime():
            header.append(self.modifiedTimeHeader)
        header.append(self.end)

        return filter(None, header)

    def findIndexByStart(self, start):
        header = self.nvim.current.buffer[:9]
        index = [i for i, line in enumerate(header) if line.startswith(start)]
        return index[0] if len(index) else None

    @neovim.command('AddFileHeader', range='', nargs='*', sync=True)
    def addFileHeader(self, args, range):
        # Set specific values for variables, such as self.author/email...
        self.getDelimiter()
        self.getFields()
        self.getCurrentTime()

        if len(self.delimiter):
            if len(self.author):
                header = self.generateHeader()
                newLineAtEnd = self.nvim.eval('g:fileheader_new_line_at_end')
                if newLineAtEnd:
                    header.append('')
                self.nvim.current.buffer.append(header, 0)
            else:
                self.message('fileheader.nvim: please set the your author field')

    @neovim.command('UpdateFileHeader', range='', nargs='*', sync=True)
    def updateFileHeader(self, args, range):
        # Set specific values for variables, such as self.author/email...
        self.getDelimiter()
        self.getFields()
        self.getCurrentTime()

        current = self.nvim.current.buffer

        if len(self.delimiter):
            authorStart = self.char + authorTpl.substitute(author='')
            authorIndex = self.findIndexByStart(authorStart)
            # if file headers don't exist, then quit
            if authorIndex is None:
                return

            # Try to get headers indexs
            emailStart = self.char + emailTpl.substitute(email= '')
            emailIndex = self.findIndexByStart(emailStart)
            byStarts = self.char + modifiedByTpl.substitute(modifiedBy = '')
            byIndex = self.findIndexByStart(byStarts)
            timeStarts = self.char + modifiedTimeTpl.substitute(modifiedTime = '')
            timeIndex = self.findIndexByStart(timeStarts)

            # Use authorIndex as a position mark
            # emailHeader:        authorIndex+1
            # dateHeader:         authorIndex+2  (won't be changed)
            # modifiedByHeader:   authorIndex+3
            # modifiedTimeHeader: authorIndex+4

            if self.showEmail():
                # if email header exists
                if emailIndex:
                    current[authorIndex+1] = self.emailHeader
                else:
                    current.append(self.emailHeader, authorIndex+1)
            else:
                if emailIndex:
                    current[authorIndex+1] = None
                authorIndex -= 1

            if self.showModifiedBy():
                # if modifiedBy header header exists
                if byIndex:
                    current[authorIndex+3] = self.modifiedByHeader
                else:
                    current.append(self.modifiedByHeader, authorIndex+3)
            else:
                if byIndex:
                    current[authorIndex+3] = None
                authorIndex -= 1

            if self.showModifiedTime():
                # if modifiedTime header header exists
                if timeIndex:
                    current[authorIndex+4] = self.modifiedTimeHeader
                else:
                    current.append(self.modifiedTimeHeader, authorIndex+4)
            else:
                if timeIndex:
                    current[authorIndex+4] = None
                authorIndex -= 1
