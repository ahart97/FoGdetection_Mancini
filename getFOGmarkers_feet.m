function IFOG_feet=getFOGmarkers_feet(Rfoot_acc,Lfoot_acc,Rfoot_gyr,Lfoot_gyr,sampleRate);

    

%% resample from 128 to 200
Rfoot=resample(Rfoot_gyr,200,sampleRate);
Lfoot=resample(Lfoot_gyr,200,sampleRate);


feet(:,1)=Rfoot;
feet(:,2)=Lfoot;

%% Low pass filter
[A,B]=butter(4,5/(200/2));
feet_f=filtfilt(A,B,feet);

se=length(Rfoot);

%% R and L angular velocities correlation
cross_1=xcov(feet(1:se,1),feet(1:se,2));
crosscov=cross_1;
for k=1:length(crosscov);
if crosscov(k)==max(crosscov);
shiftSIGN=k;
end
end

%startsync=shiftSIGN-(round(length(crosscov)/2));
startsync=shiftSIGN-((length(crosscov)/2));


%%% Figure 
% figure
% subplot(2,1,1)
% plot(feet_f(abs(startsync):se,1),'b')
% hold on
% plot(feet_f(1:se-(abs(startsync)-1),2),'m')
% legend('R leg','L leg')
% title('R and L angular velocity')
% ylabel('degrees/s')
% xlabel('Frame')
% 
t_feet1=feet_f(round(abs(startsync)):se,1);
t_feet2=feet_f(1:se-(round(abs(startsync))-1),2);
% 
% figure;
% plot(t_feet1);hold on;
% plot(t_feet2)
j=1:200:length(t_feet1);
if length(t_feet1)>200*5%%%15%% Ideally there is no condition like this once we find bout duration greater than 10 sec
    for z=1:length(j)-2
        a=corrcoef(t_feet1(j(z):j(z+1)),t_feet2(j(z):j(z+1)));
        feet_corr(z)=a(1,2);
        % figure;plot(t_feet1(j(z):j(z+1)),t_feet2(j(z):j(z+1)))
        % pause
    end
    
    ab_feet_corr=abs(feet_corr);
    ab_feet_corr_log=ab_feet_corr < 0.50;
    
    IFOG_feet.Mcorr=mean(ab_feet_corr);
    IFOG_feet.SDcorr=std(ab_feet_corr);
    
    
else
    
    IFOG_feet.Mcorr=NaN;
    IFOG_feet.SDcorr=NaN;
end

%%% Percentage time frozen

fc2=200;
xx=resample(Rfoot_acc,fc2,sampleRate);
yy=resample(Lfoot_acc,fc2,sampleRate);
x=xx(round(abs(startsync)):se,1);
y=yy(1:se-(round(abs(startsync))-1),1);
if length(x)>fc2*5%% Ideally there is no condition like this once we find bout duration greater than 10 sec

i=1:(fc2):(length(x)-(fc2)-1);
al=length(i);
for k=1:al-1



L=length(x(i(k):i(k+1)))-1;
f=0:fc2/L:(fc2/L)*(L-1);
LF=find(f==3); % 
HF=find(f==10); %%% now try 1 
LLF=find(f==0);
Pxx = abs(fft(detrend(x(i(k):i(k+1)))))/(L/2);
Pyy = abs(fft(detrend(y(i(k):i(k+1)))))/(L/2);
Ratio_x(k)=sum(Pxx(LF:HF)).^2/sum(Pxx(LLF:LF)).^2;
Ratio_y(k)=sum(Pyy(LF:HF)).^2/sum(Pyy(LLF:LF)).^2;


% 
end
for f=1:length(Ratio_x)
if Ratio_x(f)>10 || Ratio_y(f)>10  %% also tried with 10
%if Ratio_x(f)<1e-4 || Ratio_y(f)<1e-4 
percF(f)=1;
else
percF(f)=0;
end
end
A=find(percF==1);
B=length(percF);
IFOG_feet.FoGtime=(100*length(A))/B;




for f=1:length(percF)
if percF(f)==1 && ab_feet_corr_log(f)==1
percF_final(f)=1;
else
percF_final(f)=0;
end
end
%%%%%%%% Without Merging FOG Episdoes%%%%%%%%%%%%%%%
Merged_percF_final=percF_final;

%%%%%% Merging FOG Episdoes with 1 sec apart
Merged_percF_final=percF_final;
FOG_episode=find(percF_final==1);
FOG_episode_diff=diff(find(percF_final==1));
indices_1=find(FOG_episode_diff==2);
Merged_percF_final(FOG_episode(indices_1)+1)=1;
% % 
%%%%%%%% Merging FOG Episdoes with 2 sec apart
indices_2=find(FOG_episode_diff==3);
Merged_percF_final(FOG_episode(indices_2)+1)=1;
Merged_percF_final(FOG_episode(indices_2)+2)=1;
% % 
% %%%%%%%% Merging FOG Episdoes with 3 sec apart
% indices_3=find(FOG_episode_diff==4)
% Merged_percF_final(FOG_episode(indices_3)+1)=1;
% Merged_percF_final(FOG_episode(indices_3)+2)=1;
% Merged_percF_final(FOG_episode(indices_3)+3)=1;
% % % 
% % % %%%%%%%% Merging FOG Episdoes with 4 sec apart
% indices_4=find(FOG_episode_diff==5)
% Merged_percF_final(FOG_episode(indices_4)+1)=1;
% Merged_percF_final(FOG_episode(indices_4)+2)=1;
% Merged_percF_final(FOG_episode(indices_4)+3)=1;
% Merged_percF_final(FOG_episode(indices_4)+4)=1;
% 
% % %%%%%%%% Merging FOG Episdoes with 5 sec apart
% indices_5=find(FOG_episode_diff==6)
% Merged_percF_final(FOG_episode(indices_5)+1)=1;
% Merged_percF_final(FOG_episode(indices_5)+2)=1;
% Merged_percF_final(FOG_episode(indices_5)+3)=1;
% Merged_percF_final(FOG_episode(indices_5)+4)=1;
% Merged_percF_final(FOG_episode(indices_5)+5)=1;


N=find(Merged_percF_final==1);
M=length(Merged_percF_final);
IFOG_feet.FoGtime=(100*length(N))/M;
IFOG_feet.NN=length(N);
IFOG_feet.MM=M;



indices_for_distribution=find(Merged_percF_final)';
O=length(indices_for_distribution);
Very_short_FOG=0;
Short_FOG=0;
Long_FOG=0;
Very_Long_FOG=0;
Q = [true; diff(Merged_percF_final(:)) ~= 0];   % TRUE if values change
B = Merged_percF_final(Q);                      % Elements without repetitions
Z = find([Q', true]);          % Indices of 1
V = diff(Z);    
look_at=[B',V'];

for TT=1:size(look_at,1)
    if look_at(TT,1)==1 && look_at(TT,2)==1
        Very_short_FOG=Very_short_FOG+1;
    elseif look_at(TT,1)==1 && (look_at(TT,2)>=2 && look_at(TT,2)<=5)
        Short_FOG=Short_FOG+1;
    elseif look_at(TT,1)==1 && (look_at(TT,2)>5 && look_at(TT,2)<=30)
        Long_FOG=Long_FOG+1;
    elseif look_at(TT,1)==1 && (look_at(TT,2)>30)
        Very_Long_FOG=Very_Long_FOG+1;
    end
end

IFOG_feet.Very_short_FOG= Very_short_FOG;
IFOG_feet.Short_FOG= Short_FOG;
IFOG_feet.Long_FOG= Long_FOG;
IFOG_feet.Very_Long_FOG=Very_Long_FOG;
else
    IFOG_feet.FoGtime=NaN;
    IFOG_feet.Mcorr=NaN;
    IFOG_feet.SDcorr=NaN;
    IFOG_feet.Very_short_FOG=NaN;
    IFOG_feet.Short_FOG= NaN;
    IFOG_feet.Long_FOG=NaN;
     IFOG_feet.Very_Long_FOG=NaN;
    IFOG_feet.NN=NaN;
    IFOG_feet.MM=NaN;
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%----------------------



