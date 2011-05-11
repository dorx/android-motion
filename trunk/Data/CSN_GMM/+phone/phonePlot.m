function phonePlot(file)
% phonePlot - plot a .acsn file of phone acceleration
%
% Input: 
%   file - path to a .acsn file (optional)
%

import phone.*
import check.*

if nargin == 0
    [name, pathName] = uigetfile('.acsn');
    file = [pathName name];
end


if ~isFile(file, 'acsn')
    error([file ' cannot be found or is not an acsn file.'])
end

% load the file
phoneRecord = PhoneRecord(file);

% display meta data?

h = phoneRecord.display();

saveas(h, name, 'png');


% figure()
% 
% data = phoneRecord.data;
% accel = data(1:3, :);
% times = data(4,:);
% 
% xLabelString = 'seconds';
% 
% % if the record is long, scale to minutes?
% if max(times) > 300
%     times = times / 60;
%     xLabelString = 'minutes';
% end
% 
% plot(times, accel);
% xlabel(xLabelString)
% ylabel('m/s^2')

end
