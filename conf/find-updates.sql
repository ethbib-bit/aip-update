select 
	SIP_NAME, AMD_ID, SUBMIT_TIMESTAMP, WORKFLOW_EXECUTION_ID, SOURCE_PATH, SIP_PATH, SIP_STATUS, DOI
from (
	select
		SIP_NAME, AMD_ID, SUBMIT_TIMESTAMP, WORKFLOW_EXECUTION_ID, SOURCE_PATH, SIP_PATH, SIP_STATUS, DOI,
		min(SUBMIT_TIMESTAMP) over (partition by SIP_NAME) min_datum
	from (
		select 
			updt.SIP_NAME, updt.AMD_ID, updt.SIP_STATUS, updt.SUBMIT_TIMESTAMP, updt.WORKFLOW_EXECUTION_ID, updt.SOURCE_PATH, updt.SIP_PATH, updt.DOI
		from
			(select 
				rmv.SIP_NAME, rmv.AMD_ID, rmv.SIP_STATUS, rmv.SUBMIT_TIMESTAMP, rmv.WORKFLOW_EXECUTION_ID, rmv.SOURCE_PATH, rmv.SIP_PATH, rmv.DOI
			from
				#QUEUETABLE# rmv
			where rmv.SIP_NAME NOT IN ( 
				select 
					SIP_NAME
				from
					#QUEUETABLE#
				where
					SIP_STATUS = 'AIP_UPDATE_WAITING' OR SIP_STATUS = 'AIP_UPDATE_ERROR' OR SIP_STATUS = 'MD_UPDATE_ERROR'
			)) updt
		INNER JOIN (
			select 
				SIP_NAME, AMD_ID, SIP_STATUS, SUBMIT_TIMESTAMP, WORKFLOW_EXECUTION_ID, SOURCE_PATH, SIP_PATH, DOI
			from
				#QUEUETABLE# 
			where
				SIP_STATUS = 'FINISHED'
		) subm
		on updt.SIP_NAME = subm.SIP_NAME
		where
			updt.SIP_STATUS = 'FEEDER_UPDATED'
	)
) 
where 
	SUBMIT_TIMESTAMP = min_datum
order by 
	SUBMIT_TIMESTAMP ASC
fetch first #LIMIT# rows only