function keys = psychsr_key_reset
    disp('Press enter, and then do NOT press any keys for 3 seconds.')
    pause
    for i = 1:3
        pause(1)
        fprintf('%d... ',i)
        if i == 2
        [a, b, key] = KbCheck;
        end
    end
    keys = find(key == 1);
    DisableKeysForKbCheck(keys);
    fprintf('\nKeys reset.\n')
end
