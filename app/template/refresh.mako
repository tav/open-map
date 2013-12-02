<div class="alert">${alert}</div>

% if skipped:
    % if len(skipped) == 1:
    <p>But 1 row was skipped due to:</p>
    % else:
    <p>But ${len(skipped)} rows were skipped due to:</p>
    % endif
    <blockquote>
    % for row, entry, reason in skipped:
        <div><span class="skip-reason">#${row}: ${reason}</span></div>
        <div class="skip-entry">
            % for line in entry.split(', '):
            % if line.strip():
                ${line.strip()|h}<br>
            % endif
            % endfor
            </div>
    % endfor
    </blockquote>
% endif