function [ contains, trueName] = containsFile( dirName, fileName)
% containsFile - case-insensitive file search. Non-recursive
%
% Input:
%   dirName - path to directory
%   fileName - name of file to look for.
%
% Output:
%   contains - (bool) true if file is found
%   trueName - name of matching file (with correct case), or '' if not found.
%
import file.*
import check.*
import java.lang.String

[ ~, cNames ] = listFiles( dirName);

contains = false;
trueName = '';

for i=1:length(cNames)
   name = cNames{i};
   
   nameString = String(name);
   nameString = nameString.toLowerCase().trim();
   
   fileString = String(fileName);
   fileString = fileString.toLowerCase().trim();
   
   if nameString.compareToIgnoreCase(fileString) == 0 % 0 means the same
      contains = true;
      trueName = name;
      return
   end
   
end

end

