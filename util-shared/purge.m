function purge
close all;
% t_close_biographs
drawnow;

% http://www.mathworks.com/matlabcentral/answers/96076-is-there-a-way-to-close-all-opened-matlab-simulink-figures-at-once
% KILL  close all open figures and simulink models.
% Close all figures.
    % h=findall(0);
    % delete(h(2:end));
delete(findall(0,'Type','figure'))
% Close all Simulink models.
% bdclose('all')