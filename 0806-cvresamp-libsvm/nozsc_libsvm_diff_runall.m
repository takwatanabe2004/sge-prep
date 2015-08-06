disp('======== ASD vs TDI ==============')
try, nozsc_TRdiff_DX_male_v12v06, end;
try, nozsc_TRdiff_DX_male_v24v06, end;
try, nozsc_TRdiff_DX_male_v24v12, end;
try, nozsc_FAdiff_DX_male_v24v12, end;
try, nozsc_FAdiff_DX_male_v24v06, end;
try, nozsc_FAdiff_DX_male_v12v06, end;

disp('======== HR+ vs LR- ==============')
try, nozsc_FAdiff_HRpLRm_male_v12v06, end;
try, nozsc_FAdiff_HRpLRm_male_v24v06, end;
try, nozsc_FAdiff_HRpLRm_male_v24v12, end;
try, nozsc_TRdiff_HRpLRm_male_v24v12, end;
try, nozsc_TRdiff_HRpLRm_male_v24v06, end;
try, nozsc_TRdiff_HRpLRm_male_v12v06, end;

disp('======== HR+ vs HR- ==============')
try, nozsc_TRdiff_HRpHRm_male_v12v06, end;
try, nozsc_TRdiff_HRpHRm_male_v24v06, end;
try, nozsc_TRdiff_HRpHRm_male_v24v12, end;
try, nozsc_FAdiff_HRpHRm_male_v24v12, end;
try, nozsc_FAdiff_HRpHRm_male_v24v06, end;
try, nozsc_FAdiff_HRpHRm_male_v12v06, end;

disp('======== Risk ==============')
try, nozsc_FAdiff_Risk_male_v12v06, end;
try, nozsc_FAdiff_Risk_male_v24v06, end;
try, nozsc_FAdiff_Risk_male_v24v12, end;
try, nozsc_TRdiff_Risk_male_v24v12, end;

disp('======== Gender ==============')
try, nozsc_TRdiff_Gender_v12v06, end;
try, nozsc_TRdiff_Gender_v24v06, end;
try, nozsc_TRdiff_Gender_v24v12, end;
try, nozsc_FAdiff_Gender_v24v12, end;
try, nozsc_FAdiff_Gender_v24v06, end;
try, nozsc_FAdiff_Gender_v12v06, end;
