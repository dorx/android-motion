function  timeSeriesToCsv( timeSeries, fileName )
% timeSeriesToCsv - write a CSV file, containing the data of the time
% series
%   
% Input

data = timeSeries.X; 

% I'm not sure why, but I think each data point should be arow, when
% written to csv

data = transpose(data);

% write to CSV

csvwrite(fileName, data);

end

