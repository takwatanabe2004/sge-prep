disp('======== ASD vs TDI ==============')

try, FAdiff_DX_male_v12v06, end;
try, FAdiff_DX_male_v24v06, end;
try, FAdiff_DX_male_v24v12, end;
try, TRdiff_DX_male_v24v12, end;
try, TRdiff_DX_male_v24v06, end;
try, TRdiff_DX_male_v12v06, end;

disp('======== HR+ vs LR- ==============')

try, TRdiff_HRpLRm_male_v12v06, end;
try, TRdiff_HRpLRm_male_v24v06, end;
try, TRdiff_HRpLRm_male_v24v12, end;
try, FAdiff_HRpLRm_male_v24v12, end;
try, FAdiff_HRpLRm_male_v24v06, end;
try, FAdiff_HRpLRm_male_v12v06, end;

disp('======== HR+ vs HR- ==============')

try, FAdiff_HRpHRm_male_v12v06, end;
try, FAdiff_HRpHRm_male_v24v06, end;
try, FAdiff_HRpHRm_male_v24v12, end;
try, TRdiff_HRpHRm_male_v24v12, end;
try, TRdiff_HRpHRm_male_v24v06, end;
try, TRdiff_HRpHRm_male_v12v06, end;



