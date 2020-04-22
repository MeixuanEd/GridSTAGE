% This code implements the attacks: Ramp, Step and Poisoning
% This code is called every time step during the course of the attack
% At each time step, the actual Voltage magnitude, voltage angle, frequency
% and rate of change of frequency measurements are corrupted according to
% the user-defined attack characteristics. 

if strcmp(AT,'Poisoning')
    
    if t > attack.start_time_in_sec && t < attack.end_time_in_sec
        row_location = find(PMU_samples == k, 1);
        row_location_fdot = find(PMU_samples_fdot == k, 1);
        
        if ~isempty(row_location)
            PMU.Vm(row_location, AttackLocation) = PMU.Vm(row_location,AttackLocation)+(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
            PMU.Va(row_location, AttackLocation) = PMU.Va(row_location,AttackLocation)+(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
            PMU.f(row_location, AttackLocation)  = PMU.f(row_location,AttackLocation)+(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
        end
        
        if ~isempty(row_location_fdot)
            PMU.fdot(row_location_fdot, AttackLocation)  = PMU.fdot(row_location_fdot,AttackLocation)+(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
        end
    end
    
else
    % Ramp or Step attacks 
    if t > attack.start_time_in_sec && t < attack.end_time_in_sec
        row_location = find(PMU_samples == k, 1);
        row_location_fdot = find(PMU_samples_fdot == k, 1);
        
        if ~isempty(row_location)
            PMU.Vm(row_location, AttackLocation) = PMU.Vm(row_location,AttackLocation).*(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
            PMU.Va(row_location, AttackLocation) = PMU.Va(row_location,AttackLocation).*(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
            PMU.f(row_location, AttackLocation)  = PMU.f(row_location,AttackLocation).*(AttackVector.MultiplicativeFactor(:,k-AttackVector.attack_start_step))';
        end
        
        if ~isempty(row_location_fdot)
            PMU.fdot(row_location_fdot, AttackLocation)  = PMU.fdot(row_location_fdot,AttackLocation).*AttackVector.MultiplicativeFactor(k-AttackVector.attack_start_step);
        end
    end
    
end