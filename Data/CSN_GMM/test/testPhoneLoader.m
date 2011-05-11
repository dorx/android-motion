function test_suite = testPhoneLoader
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testLoadAcsnFile()
% Load an acsn file without crashing.
%
% Note: an error like "Directory name too long..." probably means a
% variable was named 'path', but not set, so the matlab 'path' command was
% called unintentionally

import phone.*

acsnFile = 'testData/walk.acsn';
[D, Fs] = PhoneLoader.loadAcsnFile(acsnFile);

assertEqual(4, size(D,1));
assertTrue( Fs > 0 )


% ------------------------------------------------------------------------

function testLoadAcsnDir()
% Load an acsn directory without crashing.
%
% Note: an error like "Directory name too long..." probably means a
% variable was named 'path', but not set, so the matlab 'path' command was
% called unintentionally
import phone.*


acsnDir = 'testData/acsnDir';

[cD, cFs, cNames] = PhoneLoader.loadAcsnDir(acsnDir);

% all three sell arrays should have the same size
nFiles = length(cD);
assertEqual(nFiles, 3); % the three acsn files should have been loaded, but not the fourth (non-acsn) file
assertEqual( length(cFs), nFiles)
assertEqual( length(cNames), nFiles)


% ------------------------------------------------------------------------



% ------------------------------------------------------------------------