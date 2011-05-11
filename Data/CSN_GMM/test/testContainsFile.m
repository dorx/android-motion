function test_suite = testContainsFile
clear all; % to reload class definitions
initTestSuite;
% xUnit test suite. Functions must not end with "end" statement.
%
% author: Matt Faulkner

% ------------------------------------------------------------------------

function testSimple()
    import file.*
    
    dirName = 'testData';
    fileName = 'walk.acsn';

    [ contains, trueName] = containsFile( dirName, fileName);
    
    assertTrue(contains);
    assertEqual(trueName, fileName);


% ------------------------------------------------------------------------

function testCaseMismatch()
import file.*
    
    dirName = 'testData';
    fileName = 'wAlK.aCsn';

    [ contains, trueName] = containsFile( dirName, fileName);
    
    assertTrue(contains);
    assertEqual(trueName, 'walk.acsn');

% ------------------------------------------------------------------------

function testFileNotFound()
import file.*
    
    dirName = 'testData';
    fileName = 'fileDoesntExist.acsn';

    [ contains, trueName] = containsFile( dirName, fileName);
    
    assertFalse(contains);
    assertEqual(trueName, '');


% ------------------------------------------------------------------------